#!/usr/bin/env python3
import os
import json
import re
import sys
from xml.etree import ElementTree as ET


class MudletXMLPackageExtractor:
    NUMBERED_JSON_REGEX = re.compile(r"\.?[\d+]*\.json")
    PACKAGE_TAGS = tuple(
        ("%sPackage" % tag for tag in ("Trigger", "Timer", "Alias", "Script", "Key"))
    )

    def __init__(self, overwrite=False):
        self.overwrite = bool(overwrite)

    def __call__(self, tree, dirpath):
        root = tree.getroot()

        if root.tag != "MudletPackage":
            raise ValueError("Are you sure '%s' is a Mudlet Package?" % filepath)
        else:
            print(
                "Parsing Mudlet Package (version: %s)"
                % root.attrib.get("version", "unknown")
            )

        dirpath = os.path.abspath(dirpath)
        for pkg_tag in self.PACKAGE_TAGS:
            group_tag = pkg_tag.replace("Package", "Group")
            node_tag = group_tag.replace("Group", "")
            group_type = node_tag + ("s" if not node_tag.endswith("s") else "es")
            dirpath = os.path.join(dirpath, group_type)
            os.mkdir(dirpath)
            for group in root.find(pkg_tag) or ():
                self.extract_group(group, dirpath, node_tag)
            dirpath = "/" + os.path.join(*os.path.normpath(dirpath).split("/")[:-1])

    def extract_group(self, group, dirpath, node_tag):
        group_info = self.get_node_info(group)
        group_name = group_info["name"]
        if group_info.get("attribs", {}).get("isActive") == "no":
            group_name = ".%s" % group_name
        dirpath = os.path.join(dirpath, group_name)
        try:
            os.mkdir(dirpath)
        except FileExistsError:
            pass

        self.write_node(group, dirpath, append_to_name="__group")
        for node in group.findall(node_tag):
            # Some nodes masquerade as groups (containers)
            # and contain more of themselves
            if node.find(node_tag) is not None:
                self.extract_group(node, dirpath, node_tag)
            else:
                self.write_node(node, dirpath)
        for subgroup in group.findall("%sGroup" % node_tag):
            self.extract_group(subgroup, dirpath, node_tag)

    def get_node_info(self, node):
        self.unknowns = getattr(self, "unknowns", 1)
        node_info = {"attribs": node.attrib, "type": node.tag.lower()}
        node_info.update(
            {
                child.tag: child.text
                for child in node
                if node.tag != "%sGroup" % child.tag
            }
        )

        if node_info.get("name") is None:
            node_info["name"] = "Unknown %s %i" % (node.tag, self.unknowns)
            self.unknowns += 1

        node_info["name"] = node_info["name"].replace("/", "|").replace("\\", "|")

        if node.tag == "Trigger":
            node_info["matches"] = list(
                zip(
                    (tag.text for tag in node.find("regexCodeList")),
                    (tag.text for tag in node.find("regexCodePropertyList")),
                )
            )

        return node_info

    def write_node(self, node, dirpath, append_to_name=""):
        node_info = self.get_node_info(node)
        filename = "%s%s.json" % (node_info["name"], append_to_name)
        filename = self._get_next_available_filename(dirpath, filename)
        is_active = node_info.get("attribs", {}).get("isActive") == "yes"
        if not is_active:
            filename = ".%s" % filename  # 'hidden' file
        with open(os.path.join(dirpath, filename), "w") as filestore:
            filestore.write(json.dumps(node_info, indent=4))
        if node_info.get("script"):
            lua_filename = filename.replace(".json", ".lua")
            with open(os.path.join(dirpath, lua_filename), "w") as luafile:
                print(node_info["script"], file=luafile)

    def _get_next_available_filename(self, dirpath, filename):
        i = 1
        while os.path.exists(os.path.join(dirpath, filename)):
            filename = self.NUMBERED_JSON_REGEX.sub(".%i.json" % i, filename)
            i += 1
        return filename


class MudletXMLCompiler:
    def __init__(self, package_name, package_path=None):
        self.package_name = str(package_name)
        self.package = ET.Element("MudletPackage")
        self.package.attrib["version"] = "1.001"
        self.tree = ET.ElementTree(self.package)

        package_tags = list(MudletXMLPackageExtractor.PACKAGE_TAGS)
        package_tags.insert(3, "ActionPackage")
        for package_tag in package_tags:
            ET.SubElement(self.package, package_tag)
        ET.SubElement(ET.SubElement(self.package, "HelpPackage"), "helpURL")

        self.package_path = os.path.abspath(package_path or os.getcwd())

    @property
    def package_file(self):
        return "%s.xml" % self.package_name

    def create_groups(self, groups, path):
        data_type = parent = None
        for group in groups:
            path = os.path.join(path, group)
            cfg_file_path = os.path.join(path, "%s__group.json" % group)
            is_active, group = not group.startswith("."), group.lstrip(".")
            try:
                with open(cfg_file_path) as cfg_file:
                    config = json.loads(cfg_file.read())
            except (IOError, OSError):
                raise RuntimeError("Missing config file! %s" % cfg_file_path)
            except json.JSONDecodeError:
                raise RuntimeError("Malformed config file! %s" % cfg_file_path)
            else:
                if data_type is None:
                    data_type = config["type"].lower().replace("group", "")
                    parent = self.package.find("%sPackage" % data_type.title())
                group_tag = "%sGroup" % data_type.title()
                try:
                    parent = [
                        g
                        for g in parent.findall(group_tag)
                        if self.node_name(g) == group
                    ][0]
                except IndexError:
                    parent = ET.SubElement(parent, group_tag)
                    parent.attrib.update(config.get("attribs", {}))
                    parent.attrib["isActive"] = "yes" if is_active else "no"
                    sub_node_info = self._get_sub_nodes_by_type(data_type, group)
                    for key, default in sub_node_info.items():
                        subtag = ET.SubElement(parent, key)
                        subtag.text = config.get(key, default)
        return parent or None

    def create_leaf(self, config_path, config_file, parent=None):
        full_config_path = os.path.join(config_path, config_file)
        with open(full_config_path) as cfg_file:
            config = json.loads(cfg_file.read())

        try:
            with open(full_config_path[:-4] + "lua") as script_cfg_file:
                config["script"] = script_cfg_file.read()
        except (IOError, OSError):
            pass

        data_type = config["type"].lower()
        default_attribs = self._get_attribs_by_type(data_type)
        elem = ET.SubElement(
            parent, data_type.title(), config.get("attribs", default_attribs)
        )
        is_active = not config_file.startswith(".")
        elem.attrib["isActive"] = "yes" if is_active else "no"
        sub_node_info = self._get_sub_nodes_by_type(data_type, config_file.lstrip("."))
        for key, default in sub_node_info.items():
            subtag = ET.SubElement(elem, key)
            subtag.text = config.get(key, default)

        regex_list = elem.find("regexCodeList")
        regex_prop_list = elem.find("regexCodePropertyList")
        if regex_list is not None and regex_prop_list is not None:
            for code, prop in config.get("matches", ()):
                string = ET.SubElement(regex_list, "string")
                string.text = code
                integer = ET.SubElement(regex_prop_list, "integer")
                integer.text = prop

    def compile(self):
        package_path = os.path.abspath(self.package_path)
        for subpackage in ("Triggers", "Timers", "Aliases", "Scripts", "Keys"):
            subpackage_path = os.path.join(package_path, subpackage)
            if os.path.exists(subpackage_path):
                for dirpath, subdirs, filenames in os.walk(subpackage_path):
                    groups = [
                        dirname
                        for dirname in os.path.normpath(
                            dirpath.replace(subpackage_path, "")
                        )
                        .lstrip("/")
                        .split("/")
                        if dirname != "." and not dirname.startswith("_")
                    ]
                    parent = self.create_groups(groups, subpackage_path)
                    for filename in filenames:
                        if (
                            filename.endswith(".json")
                            and not filename.endswith("__group.json")
                            and not filename.startswith("_")
                        ):
                            self.create_leaf(dirpath, filename, parent)
        pkg_path = os.path.join(package_path, self.package_file)
        self.tree.write(pkg_path)
        print("%s successfully written." % pkg_path)

    def node_name(self, node):
        name = node.find("name")
        return None if name is None else name.text

    def _get_attribs_by_type(self, type_):
        return {
            "trigger": {
                "isActive": "yes",
                "isFolder": "no",
                "isTempTrigger": "no",
                "isMultiline": "no",
                "isPerlSlashGOption": "no",
                "isColorizerTrigger": "no",
                "isFilterTrigger": "no",
                "isSoundTrigger": "no",
                "isColorTrigger": "no",
                "isColorTriggerFg": "no",
                "isColorTriggerBg": "no",
            },
            "timer": {
                "isActive": "yes",
                "isFolder": "no",
                "isTempTimer": "no",
                "isOffsetTimer": "no",
            },
        }.get(type_.lower(), {"isActive": "yes", "isFolder": "no"})

    def _get_sub_nodes_by_type(self, type_, name):
        return {
            "trigger": {
                "name": name,
                "script": "",
                "triggerType": 0,
                "conditionLineDelta": 0,
                "mStayOpen": 0,
                "mCommand": "",
                "packageName": "",
                "mFgColor": "",
                "mBgColor": "",
                "mSoundFile": "",
                "colorTriggerFgColor": "",
                "colorTriggerBgColor": "",
                "regexCodeList": "",
                "regexCodePropertyList": "",
            },
            "alias": {
                "name": "",
                "script": "",
                "command": "",
                "packageName": "",
                "regex": "",
            },
            "script": {
                "name": "",
                "packageName": "",
                "script": "",
                "eventHandlerList": "",
            },
            "key": {
                "name": "",
                "script": "",
                "command": "",
                "packageName": "",
                "keyCode": "",
                "keyModifier": "",
            },
            "timer": {
                "name": "",
                "script": "",
                "command": "",
                "packageName": "",
                "time": "",
            },
            "variable": {
                "name": "",
                "keyType": "",
                "value": "",
                "valueType": "",
            },
        }.get(type_.lower(), {})


def die(code=1):
    print()
    print("Exiting...", file=sys.stderr)
    sys.exit(int(code))


def run_interactive():
    main_menu = """
    Nasuta's Mudlet Packaging Tools
    ===============================

    1. Extract a package into files and folders
    2. Compile files and folders into a package
    3. Quit

    Your choice? """
    package_path_question = """
    Enter the path to your package: """
    package_name_question = """
    Enter the name of your package: """
    source_code_question = """
    Enter the path to your source code: """
    target_path_question = """
    Enter the path to store the result: """

    menu_opt = 0
    while not (0 < menu_opt < 4):
        try:
            menu_opt = int(input(main_menu))
        except ValueError:
            pass
        except (KeyboardInterrupt, EOFError):
            die()
            break

    if menu_opt == 1:
        try:
            pkg_path = os.path.abspath(input(package_path_question))
            while not os.path.exists(pkg_path):
                print("\tCan't find this package!", file=sys.stderr)
                pkg_path = os.path.abspath(input(package_path_question))

            tgt_path = os.path.abspath(input(target_path_question))
        except (KeyboardInterrupt, EOFError):
            die()
        else:
            if len(os.listdir(tgt_path)):
                print("Remove the target directory first!", file=sys.stderr)
                die()
            extractor = MudletXMLPackageExtractor(overwrite=False)
            data = ET.parse(pkg_path)
            extractor(data, tgt_path)
    elif menu_opt == 2:
        try:
            pkg_path = os.path.abspath(input(source_code_question))
            while not os.path.exists(pkg_path):
                print("\tCan't find this package!", file=sys.stderr)
                pkg_path = os.path.abspath(input(source_code_question))

            pkg_name = input(package_name_question)
        except (KeyboardInterrupt, EOFError):
            die()
        else:
            compiler = MudletXMLCompiler(pkg_name, pkg_path)
            compiler.compile()


if __name__ == "__main__":
    from optparse import OptionParser

    parser = OptionParser()

    parser.add_option(
        "-c",
        "--compile",
        action="store",
        type="string",
        dest="path_to_package",
        help="Build a Mudlet package out of directories and files",
    )
    parser.add_option(
        "-i",
        "--interactive",
        action="store_true",
        dest="interactive",
        help="Run interactively (supercedes other options)",
    )
    parser.add_option(
        "-o",
        "--output",
        action="store",
        type="string",
        dest="path_to_output",
        help="Where to store the output (used with -x)",
    )
    parser.add_option(
        "-n",
        "--package-name",
        action="store",
        type="string",
        dest="package_name",
        help="Name of the compiled package (used with -c)",
    )
    parser.add_option(
        "-x",
        "--extract",
        action="store",
        type="string",
        dest="path_to_xml",
        help="Extract a Mudlet .xml package into files and directories",
    )

    opts, args = parser.parse_args()
    if opts.interactive:
        run_interactive()
    elif opts.path_to_package:  # compile
        if not opts.package_name:
            print("Must use -n flag with this option", file=sys.stderr)
            die()
        compiler = MudletXMLCompiler(opts.package_name, opts.path_to_package)
        compiler.compile()
    elif opts.path_to_xml:  # extract
        if not opts.path_to_output:
            print("Must use -o flag with this option", file=sys.stderr)
            die()
        extractor = MudletXMLPackageExtractor(overwrite=False)
        data = ET.parse(opts.path_to_xml)
        extractor(data, opts.path_to_output)
    else:
        parser.print_help()
