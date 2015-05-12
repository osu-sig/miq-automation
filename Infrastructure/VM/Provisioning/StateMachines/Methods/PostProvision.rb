###################################
#
# EVM Automate Method: PostProvision
#
# Notes: This method is used to process tasks immediately after the VM has been provisioned
#
###################################

def log(level, message)
  @method = 'PostProvision'
  @debug = true
  $evm.log(level, "#{@method} - #{message}") if @debug
end

def dump_root
  log(:info, "Root:<$evm.root> Attributes - Begin")
  $evm.root.attributes.sort.each { |k, v| log(:info, "  Attribute - #{k}: #{v}") }
  log(:info, "Root:<$evm.root> Attributes - End")
  log(:info, "")
end

begin
  log(:info, "EVM Automate Method Started")

  def set_ownership(prov)
    vm = prov.vm
    log(:info, "setting VM ownership...")
    requester = prov.miq_request.requester
    owner = $evm.vmdb('user', requester.id)
    vm.owner = owner
    vm.group = owner.current_group
    log(:info, "done setting VM ownership")
  end

  def tag_with_department(prov)
    vm = prov.vm
    log(:info, "tagging VM with department...")
    requester = prov.miq_request.requester
    requester_user = $evm.vmdb('user', requester.id)
    requester_group = requester_user.current_group
    log(:info, "User:<#{requester_user.name}> Group:<#{requester_group.description}> Tags:<#{requester_group.tags}>")
    requester_group.tags.each do |tag|
      log(:info, "group tag:<#{tag}>")
      if tag.start_with?("department")
        vm.tag_assign(tag)
        log(:info, "tagged VM <#{vm.name}> with <#{tag}>")
        break
      end
    end
  end

  #
  # Get Variables
  #
  prov = $evm.root["miq_provision"]
  log(:info, "Provisioning ID:<#{prov.id}> Provision Request ID:<#{prov.miq_provision_request.id}>")

  # Get provissioned VM from prov object
  vm = prov.vm
  unless vm.nil?
    #set_ownership(prov)
    dump_root
    tag_with_department(prov)
    log(:info, "VM:<#{vm.name}> has been provisioned")
  end

  #
  # Exit method
  #
  log(:info, "EVM Automate Method Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
