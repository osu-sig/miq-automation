###################################
#
# EVM Automate Method: MiqProvisionRequest_Approved
#
# Notes: This method is used to email the provision requester that
# VM provisioning request has been approved
#
# Events: request_approved
#
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    requester does not have a valid email address. To specify more than one email
#    address separate email address with commas. (I.e. admin@company.com,user@company.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#
###################################
# Method for logging
def log(level, message)
  @method = 'MiqProvisionRequest_Approved'
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

  ###################################
  #
  # Method: emailrequester
  #
  # Send email to requester
  #
  ###################################
  def emailrequester(miq_request, appliance)
    log(:info, "Requester email logic starting")

    # Get requester object
    requester = miq_request.requester
    requester_user = $evm.vmdb('user', requester.id)

    # Get requester email else set to nil
    requester_email = requester_user.email || nil

    # Get Owner Email else set to nil
    #owner_email = miq_request.options[:owner_email] || nil
    log(:info, "Requester email:<#{requester_email}>")

    # if to is nil then use requester_email
    to = nil
    to ||= requester_email
    to += ",#{$evm.object['to_email_address']}"

    # Get from_email_address from model unless specified below
    from = nil
    from ||= $evm.object['from_email_address']

    # Get signature from model unless specified below
    signature = nil
    signature ||= $evm.object['signature']

    # Build subject
    vm_name = miq_request.options[:vm_name]
    subject = "[MIQ] - your request for new VM #{vm_name} has been approved"

    # Build email body
    body = "Hello, "
    body += "<br><br>Your request for the new virtual machine <strong>#{vm_name}</strong> has been approved. You will be notified via email when the VM is available."
    #body += "<br><br>Approvers notes: #{miq_request.reason}"
    body += "<br><br>To view this request, go to: <a href='https://#{appliance}/miq_request/show/#{miq_request.id}'>https://#{appliance}/miq_request/show/#{miq_request.id}</a>"
    body += "<br><br>Thank you,"
    body += "<br>#{signature}"

    # Send email
    log(:info, "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
    $evm.execute(:send_email, to, from, subject, body)
  end

  # Get miq_request from root
  miq_request = $evm.root['miq_request']
  raise "miq_request missing" if miq_request.nil?
  log(:info, "Detected Request:<#{miq_request.id}> with Approval State:<#{miq_request.approval_state}>")

  # Override the default appliance IP Address below
  appliance = nil
  appliance ||= $evm.object['miq_server_hostname']

  # Email Requester
  emailrequester(miq_request, appliance)

  # Email Requester
  # emailapprover(miq_request, appliance)

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
