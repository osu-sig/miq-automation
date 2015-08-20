###################################
#
# EVM Automate Method: MiqProvision_Complete
#
# Notes: This method sends an e-mail when the following event is raised:
#
# Events: vm_provisioned
#
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    vm's owner does not have an  email address. To specify more than one email
#    address separate email address with commas. (I.e. admin@company.com,user@company.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#
###################################
# Method for logging
def log(level, message)
  @method = 'MiqProvision_Complete'
  @debug = true
  $evm.log(level, "#{@method} - #{message}") if @debug
end

def dump_root
  log(:info, "Root:<$evm.root> Attributes - Begin")
  $evm.root.attributes.sort.each { |k, v| $evm.log("info", "  Attribute - #{k}: #{v}") }
  log(:info, "Root:<$evm.root> Attributes - End")
end

begin
  log(:info, "EVM Automate Method Started")

  # Get vm from miq_provision object
  prov = $evm.root['miq_provision']
  vm = prov.vm
  raise "#{@method} - VM not found" if vm.nil?

  # Override the default appliance IP Address below
  # appliance ||= 'evmserver.company.com'
  appliance ||= $evm.object['miq_server_hostname']

  #
  # Get VM Owner Name and Email
  #
  requester = prov.miq_request.requester
  requester_user = $evm.vmdb('user', requester.id)
  log(:info, "VM requester: #{requester_user.inspect}")

  to = nil
  to = requester_user.email unless requester_user.nil?
  if to.nil?
    log(:info, "Email not sent because no recipient specified.")
    exit MIQ_OK
  end
  to += ",#{$evm.object['to_email_address']}"

  # Assign original to_email_Address to orig_to for later use
  orig_to = to

  # Get from_email_address from model unless specified below
  from = nil
  from ||= $evm.object['from_email_address']

  # Get signature from model unless specified below
  signature = nil
  signature ||= $evm.object['signature']

  # Set email Subject
  subject = "[MIQ] - new VM #{vm['name']} has been created"

  # Set the opening body to Hello
  body = "Hello,"

  # VM Provisioned Email Body
  body += "<br><br>Your request to provision the new virtual machine <strong>#{vm['name']}</strong> was completed on #{Time.now.strftime('%A, %B %d, %Y at %I:%M%p')}. "
  body += "<br><br>You can access and manage your virtual machine here: <a href='https://#{appliance}/vm_or_template/show/#{vm['id']}'>https://#{appliance}/vm_or_template/show/#{vm['id']}</a>"
  #body += "<br><br>Virtual machine <b>#{vm['name']}</b> will be available in approximately 15 minutes. "
  body += "<br><br>For Windows VM access is available via RDP and for Linux VM access is available via putty/ssh, etc. Or you can use the console feature found in the detail view of your VM. "
  body += "<br><br>This VM will automatically be retired on #{vm['retires_on'].strftime('%A, %B %d, %Y')}, unless you request an extension. " if vm['retires_on'].respond_to?('strftime')
  body += " You will receive a warning #{vm['reserved'][:retirement][:warn]} days before #{vm['name']} set retirement date." if vm['reserved'] && vm['reserved'][:retirement] && vm['reserved'][:retirement][:warn]
  body += "<br><br>Thank you,"
  body += "<br> #{signature}"

  #
  # Send email
  #
  log(:info, "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
  $evm.execute('send_email', to, from, subject, body)

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
  exit MIQ_STOP
end
