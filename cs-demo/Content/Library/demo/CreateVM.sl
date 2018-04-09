namespace: demo
flow:
  name: CreateVM
  inputs:
    - host: 10.0.46.10
    - username: "Capa1\\1284-capa1user"
    - password: Automation123
    - datacenter: Capa1 Datacenter
    - image: Ubuntu
    - folder: Students/lucav
    - prefix_list: '1-,2-,3-'
  workflow:
    - uuid:
        do:
          io.cloudslang.demo.uuid: []
        publish:
          - uuid: '${"lucav-"+uuid}'
        navigate:
          - SUCCESS: substring
    - substring:
        do:
          io.cloudslang.base.strings.substring:
            - origin_string: '${uuid}'
            - end_index: '13'
        publish:
          - id: '${new_string}'
        navigate:
          - SUCCESS: clone_vm
          - FAILURE: on_failure
    - clone_vm:
        parallel_loop:
          for: prefix in prefix_list
          do:
            io.cloudslang.vmware.vcenter.vm.clone_vm:
              - host: '${host}'
              - user: '${username}'
              - password:
                  value: '${password}'
                  sensitive: true
              - vm_source_identifier: name
              - vm_source: '${image}'
              - datacenter: '${datacenter}'
              - vm_name: '${prefix+id}'
              - vm_folder: '${folder}'
              - mark_as_template: 'false'
              - trust_all_roots: 'true'
              - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: power_on_vm
          - FAILURE: on_failure
    - power_on_vm:
        parallel_loop:
          for: prefix in prefix_list
          do:
            io.cloudslang.vmware.vcenter.power_on_vm:
              - host: '${host}'
              - user: '${username}'
              - password:
                  value: '${password}'
                  sensitive: true
              - vm_identifier: name
              - vm_name: '${prefix+id}'
              - trust_all_roots: 'true'
              - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: wait_for_vm_info
          - FAILURE: on_failure
    - wait_for_vm_info:
        parallel_loop:
          for: prefix in prefix_list
          do:
            io.cloudslang.vmware.vcenter.util.wait_for_vm_info:
              - host: '${host}'
              - user: '${username}'
              - password:
                  value: '${password}'
                  sensitive: true
              - vm_identifier: name
              - vm_name: '${prefix+id}'
              - datacenter: '${datacenter}'
              - trust_all_roots: 'true'
              - x_509_hostname_verifier: allow_all
        publish:
          - ip_list: '${str([str(x["ip"]) for x in branches_context])}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  outputs:
    - ip_list: '${ip_list}'
  results:
    - SUCCESS
    - FAILURE
extensions:
  graph:
    steps:
      uuid:
        x: 100
        y: 150
      substring:
        x: 400
        y: 150
      clone_vm:
        x: 700
        y: 150
      power_on_vm:
        x: 1000
        y: 150
      wait_for_vm_info:
        x: 1300
        y: 150
        navigate:
          1f59304a-155d-b1ac-39dd-0680514d7bd0:
            targetId: 919536b0-a97b-b7cc-426a-a13b6ced3aa8
            port: SUCCESS
    results:
      SUCCESS:
        919536b0-a97b-b7cc-426a-a13b6ced3aa8:
          x: 1600
          y: 150
