#!/usr/bin/python

from ansible.module_utils.basic import AnsibleModule
import subprocess
import os

DOCUMENTATION = '''
---
module: check_macos_privacy_permission
short_description: Check if an app has a specific macOS privacy permission
description:
    - This module checks if the specified application has the required macOS privacy permission.
options:
    app_bundle_identifier:
        description:
            - The bundle identifier of the application.
        required: true
    permission_type:
        description:
            - The type of privacy permission to check.
        required: true
'''

EXAMPLES = '''
# Check if Microsoft Teams has Screen Recording permission
- name: Check Microsoft Teams Screen Recording permission
  check_macos_privacy_permission:
    app_bundle_identifier: "com.microsoft.teams"
    permission_type: "kTCCServiceScreenCapture"
  register: result
'''


def main():
    module = AnsibleModule(
        argument_spec=dict(
            app_bundle_identifier=dict(required=True, type='str'),
            permission_type=dict(required=True, type='str'),
        ),
        supports_check_mode=True
    )

    app_bundle_identifier = module.params['app_bundle_identifier']
    permission_type = module.params['permission_type']

    db_path = os.path.expanduser('/Library/Application Support/com.apple.TCC/TCC.db')

    query = f'SELECT * FROM access WHERE client="{app_bundle_identifier}" AND service="{permission_type}" AND allowed=1;'

    try:
        output = subprocess.check_output(['sqlite3', db_path, query]).decode('utf-8')

        if output:
            module.exit_json(changed=False, msg=f'Permission {permission_type} is enabled for {app_bundle_identifier}',
                             permission_enabled=True)
        else:
            module.exit_json(changed=False,
                             msg=f'Permission {permission_type} is not enabled for {app_bundle_identifier}',
                             permission_enabled=False)

    except subprocess.CalledProcessError as e:
        module.fail_json(msg=f'Error checking permissions: {str(e)}')


if __name__ == '__main__':
    main()
