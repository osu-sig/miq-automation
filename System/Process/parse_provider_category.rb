def log(level, message)
  @method = 'parse_provider_category'
  @debug = true
  $evm.log(level, "#{@method} - #{message}") if @debug
end

def dump_root
  log(:info, "Root:<$evm.root> Attributes - Begin")
  $evm.root.attributes.sort.each { |k, v| log(:info, "  Attribute - #{k}: #{v}") }
  log(:info, "Root:<$evm.root> Attributes - End")
  log(:info, "")
end

def vm_detect_category(vm)
  return nil unless vm.respond_to?(:cloud)
  vm.cloud == true ? 'cloud' : 'infrastructure'
end

def vm_migrate_task_detect_category(vm_migrate_task)
  vm_detect_category(vm_migrate_task.source)
end

def miq_request_detect_category(miq_request)
  vm_detect_category(miq_request.source)
end

def miq_provision_detect_category(miq_provision)
  vm_detect_category(miq_provision.source)
end

def platform_category_detect_category(platform_category)
  platform_category = 'infrastructure' if platform_category == 'infra'
  platform_category
end

def category_for_key(key)
  send("#{key}_detect_category", $evm.root[key]) if $evm.root.attributes.key?(key)
end

provider_category = nil
key_found = %w(vm vm_migrate_task miq_request miq_provision platform_category).detect do |key|
  provider_category = category_for_key(key)
end

$evm.root['ae_provider_category'] = provider_category || "unknown"
log(:info, "Key: #{key_found.inspect}  Value: #{$evm.root['ae_provider_category']}")
