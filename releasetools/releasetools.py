# Copyright (C) 2026 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""vfp OTA hooks: refuse to install over a locked (retail) aboot."""

import common


def CheckAboot(info):
  # Runs before anything is written; install/ is not extracted yet at this point.
  info.script.AppendExtra(
      'package_extract_file("install/bin/check_aboot.sh", "/tmp/check_aboot.sh");')
  info.script.AppendExtra(
      'set_metadata("/tmp/check_aboot.sh", "uid", 0, "gid", 0, "mode", 0755);')
  info.script.AppendExtra(
      'run_program("/tmp/check_aboot.sh") == 0 || abort("This ROM boots straight from '
      'the boot partition and needs the unlocked prototype aboot. The retail aboot would '
      'refuse to boot it - see the README.");')


def FullOTA_Assertions(info):
  CheckAboot(info)


def IncrementalOTA_Assertions(info):
  CheckAboot(info)
