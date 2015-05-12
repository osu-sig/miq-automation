###################################
#
# EVM Automate Method: PreProvision
#
# Notes: This default method is used to apply PreProvision customizations for VMware, RHEV and Amazon provisioning
#
###################################
# Method for logging
def log(level, message)
  @method = 'PreProvision'
  $evm.log(level, "#{@method} - #{message}")
end

def dump_root
  log(:info, "Root:<$evm.root> Attributes - Begin")
  $evm.root.attributes.sort.each { |k, v| $evm.log("info", "  Attribute - #{k}: #{v}") }
  log(:info, "Root:<$evm.root> Attributes - End")
end

begin
  log(:info, "EVM Automate Method Started")

  #################################
  #
  # Method: process_vmware
  # Notes: Process vmware specific provisioning options
  #
  #################################
  def process_vmware(prov)
    #dump_root

    # Choose the sections to process
    set_size = true
    set_vlan = false
    set_folder = true
    set_resource_pool = false
    set_notes = true

    # Get information from the template platform
    template = prov.vm_template
    product  = template.operating_system['product_name'].downcase
    bitness = template.operating_system['bitness']
    log(:info, "Template:<#{template.name}> Vendor:<#{template.vendor}> Product:<#{product}> Bitness:<#{bitness}>")

    if set_size
      case prov.get_option(:number_of_cpus)
      when 's'
        num_sockets = 1
        num_cores = 1
        mem_size = '1024'
      when 'm'
        num_sockets = 2
        num_cores = 1
        mem_size = '4096'
      when 'l'
        num_sockets = 4
        num_cores = 1
        mem_size = '8192'
      when 'xl'
        num_sockets = 8
        num_cores = 1
        mem_size = '8192'
      end

      #TODO disk
      #new_disks = []
      #new_disks << {:bus=>0, :pos=>3, :sizeInMB=> 20.gigabytes / 1.megabyte}

      #prov.set_option(:disk_scsi, new_disks)
      prov.set_option(:number_of_sockets, num_sockets)
      prov.set_option(:cores_per_socket, num_cores)
      prov.set_option(:vm_memory, mem_size)
      prov.set_option(:number_of_cpus, nil)
      log(:info, "set_size finished -> prov:<#{prov.inspect}")
    end

    if set_vlan
      ###################################
      # Was a VLAN selected in dialog?
      # If not you can set one here.
      ###################################
      default_vlan = "vlan1"
      default_dvs = "portgroup1"

      if prov.get_option(:vlan).nil?
        log(:info, "Provisioning object <:vlan> updated with <#{default_vlan}>")
        prov.set_vlan(default_vlan)
        # prov.set_dvs(default_dvs)
      end
    end

    if set_folder
      ###################################
      # Drop the VM in the targeted folder if no folder was chosen in the dialog
      # The vCenter folder must exist for the VM to be placed correctly else the
      # VM will placed along with the template
      # Folder starts at the Data Center level
      ###################################
      base_folder = 'SIG DEV'

      user = prov.miq_request.requester
      group_folder = "#{base_folder}/#{user.normalized_ldap_group}"
      if prov.get_option(:placement_folder_name).nil?
        #prov.get_folder_paths.each { |key, path| log(:info, "Eligible folders:<#{key}> - <#{path}>") }
        prov.set_folder(group_folder)
        log(:info, "Provisioning object <:placement_folder_name> updated with <#{group_folder}>")
      else
        log(:info, "Placing VM in folder: <#{prov.get_option(:placement_folder_name)}>")
      end
    end

    if set_resource_pool
      if prov.get_option(:placement_rp_name).nil?
        ############################################
        # Find and set the Resource Pool for a VM:
        ############################################
        default_resource_pool = 'MyResPool'
        respool = prov.eligible_resource_pools.detect { |c| c.name.casecmp(default_resource_pool) == 0 }
        log(:info, "Provisioning object <:placement_rp_name> updated with <#{respool.name}>")
        prov.set_resource_pool(respool)
      end
    end

    if set_notes
      ###################################
      # Set the VM Description and VM Annotations  as follows:
      # The example would allow user input in provisioning dialog "vm_description"
      # to be added to the VM notes
      ###################################
      # Stamp VM with custom description
      unless prov.get_option(:vm_description).nil?
        vmdescription = prov.get_option(:vm_description)
        prov.set_option(:vm_description, vmdescription)
        log(:info, "Provisioning object <:vmdescription> updated with <#{vmdescription}>")
      end

      # Setup VM Annotations
      vm_notes =  "Owner: #{prov.miq_request.requester.normalized_ldap_group}"
      vm_notes += "\nRequested By: #{prov.miq_request.requester.name}"
      vm_notes += "\nRequester Email: #{prov.miq_request.requester.userid}"
      vm_notes += "\nSource Template: #{template.name}"
      vm_notes += "\nCustom Description: #{vmdescription}" unless vmdescription.nil?
      prov.set_vm_notes(vm_notes)
      log(:info, "Provisioning object <:vm_notes> updated with <#{vm_notes}>")
    end
  end

  #################################
  #
  # Method: process_redhat
  # Notes: Process redhat specific provisioning options
  #
  #################################
  def process_redhat(prov)
    # Choose the sections to process
    set_vlan = true
    set_notes = false

    # Get information from the template platform
    template = prov.vm_template
    product  = template.operating_system['product_name'].downcase
    log(:info, "Template:<#{template.name}> Vendor:<#{template.vendor}> Product:<#{product}>")

    if set_vlan
      # Set default VLAN here if one was not chosen in the dialog?
      default_vlan = "rhevm"

      if prov.get_option(:vlan).nil?
        prov.set_vlan(default_vlan)
        log(:info, "Provisioning object <:vlan> updated with <#{default_vlan}>")
      end
    end

    if set_notes
      ###################################
      # Set the VM Description and VM Annotations  as follows:
      # The example would allow user input in provisioning dialog "vm_description"
      # to be added to the VM notes
      ###################################
      # Stamp VM with custom description
      unless prov.get_option(:vm_description).nil?
        vmdescription = prov.get_option(:vm_description)
        prov.set_option(:vm_description, vmdescription)
        log(:info, "Provisioning object <:vmdescription> updated with <#{vmdescription}>")
      end

      # Setup VM Annotations
      vm_notes =  "Owner: #{prov.get_option(:owner_first_name)} #{prov.get_option(:owner_last_name)}"
      vm_notes += "\nEmail: #{prov.get_option(:owner_email)}"
      vm_notes += "\nSource Template: #{template.name}"
      vm_notes += "\nCustom Description: #{vmdescription}" unless vmdescription.nil?
      prov.set_vm_notes(vm_notes)
      log(:info, "Provisioning object <:vm_notes> updated with <#{vm_notes}>")
    end
  end

  #################################
  #
  # Method: process_amazon
  # Notes: Process Amazon specific provisioning options
  #
  #################################
  def process_amazon(prov)
  end # end process_amazon

  # Get provisioning object
  prov = $evm.root["miq_provision"]
  log(:info, "Provision:<#{prov.id}> Request:<#{prov.miq_provision_request.id}> Type:<#{prov.type}>")

  # Build case statement to determine which type of processing is required
  case prov.type
  when 'MiqProvisionRedhatViaIso', 'MiqProvisionRedhatViaPxe' then  process_redhat(prov)
  when 'MiqProvisionVmware' then                                    process_vmware(prov)
  when 'MiqProvisionAmazon' then                                    process_amazon(prov)
  else                                                          log(:info, "Provision Type:<#{prov.type}> does not match, skipping processing")
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
