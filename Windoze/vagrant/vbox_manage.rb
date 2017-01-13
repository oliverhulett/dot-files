# -*- mode: ruby -*-
# vi: set ft=ruby :

VM_NAME ||= ENV['VM_NAME'] || "centos_dev_vm"

def vbox_manage?
  @vbox_manage ||= ! `which VBoxManage`.chomp.empty?
end

def vm_boxes
  boxes = {}
  if vbox_manage?
    vms = `VBoxManage list vms`
    vms.split("\n").each do |vm|
      x = vm.split
      k = x[0].gsub('"','')      # vm name
      v = x[1].gsub(/[{}]/,'')   # vm UUID
      boxes[k] = v
    end
  end
  boxes
end

def vm_exists?
  vm_boxes[VM_NAME] ? true : false
end

def vm_info
  vm_exists? ? `VBoxManage showvminfo #{VM_NAME} 2> nul` : ''
end

def vm_uuid
  vm_boxes[VM_NAME]
end

def vm_state
  case vm_exists?
  when true
    vm_state = vm_info.split("\n").select {|f| f =~ /^State:/}.first || ''
    vm_state.split[1]
  when false
    ''
  end
end

def vm_running?
  vm_state == "running"
end

def vm_controller(controller)
  `VBoxManage showvminfo #{VM_NAME} 2> nul | grep "#{controller}"`
end