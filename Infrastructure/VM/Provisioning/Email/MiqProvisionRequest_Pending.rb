###################################
#
# EVM Automate Method: MiqProvisionRequest_Pending
#
# Notes: This method is launched from the not_approved method which raises the requst_pending event
# when the provisioning request is NOT auto-approved
#
# Events: request_pending
#
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    requester does not have a valid email address.To specify more than one email
#    address separate email address with commas. (I.e. admin@company.com,user@company.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#
###################################
# Method for logging
def log(level, message)
  @method = 'MiqProvisionRequest_Pending'
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
  # Build email to requester with reason
  #
  ###################################
  def emailrequester(miq_request, appliance, msg, provisionRequestApproval)
    log(:info, "Requester email logic starting")

    # Get requester object
    requester = miq_request.requester

    # Get requester email else set to nil
    requester_email = requester.email || nil

    # Get Owner Email else set to nil
    owner_email = miq_request.options[:owner_email] || nil
    log(:info, "Requester email:<#{requester_email}> Owner Email:<#{owner_email}>")

    # if to is nil then use requester_email or owner_email
    to = nil
    to ||= requester_email # || owner_email

    # If to is still nil use to_email_address from model
    to ||= $evm.object['to_email_address']

    # Get from_email_address from model unless specified below
    from = nil
    from ||= $evm.object['from_email_address']

    # Get signature from model unless specified below
    signature = nil
    signature ||= $evm.object['signature']

    vm_name = miq_request.options[:vm_name]

    # Set email subject
    subject = "[MIQ] - your request for new VM #{vm_name} has been submitted for approval"

    # Build email body
    body = "Hello,"
    body += "<br><br>Your request for the new virtual machine <strong>#{vm_name}</strong> has been submitted for approval. You will be notified via email when the request has been approved."
    body += "<br><br>To view this request, go to: <a href='https://#{appliance}/miq_request/show/#{miq_request.id}'>https://#{appliance}/miq_request/show/#{miq_request.id}</a>"
    body += "<br><br>Thank you,"
    body += "<br>#{signature}"

    # Send email to requester
    log(:info, "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
    $evm.execute(:send_email, to, from, subject, body)
  end

  ###################################
  #
  # Method: emailapprover
  #
  # Build email to approver with reason
  #
  ###################################
  def emailapprover(miq_request, appliance, msg, provisionRequestApproval)
    log(:info, "#{@method} - Approver email logic starting")

    # Get requester object
    requester = miq_request.requester

    # Get requester email else set to nil
    requester_email = requester.email || nil

    # Get Owner Email else set to nil
    owner_email = miq_request.options[:owner_email] || nil
    log(:info, "#{@method} - Requester email:<#{requester_email}> Owner Email:<#{owner_email}>")

    # Override to email address below or get to_email_address from from model
    to = nil
    to  ||= $evm.object['to_email_address']

    # Override from_email_address below or get from_email_address from model
    from = nil
    from ||= $evm.object['from_email_address']

    # Get signature from model unless specified below
    signature = nil
    signature ||= $evm.object['signature']

    vm_name = miq_request.options[:vm_name]
    vm_description = miq_request.options[:vm_description]

    # Set email subject
    if provisionRequestApproval
      subject = "[MIQ] - request for new VM #{vm_name} pending"
    else
      subject = "[MIQ] - request for new VM #{vm_name} pending due to quota limitations"
    end

    # Build email body
    body = "#{requester_email} has submitted a request for a new VM: <strong>#{vm_name}</strong>"
    body += "</br></br>Description: #{vm_description}"
    body += "</br></br>To view this request, go to: <a href='https://#{appliance}/miq_request/show/#{miq_request.id}'>https://#{appliance}/miq_request/show/#{miq_request.id}</a>"

    # Send email to approver
    log(:info, "#{@method} - Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
    $evm.execute(:send_email, to, from, subject, body)
  end

  #dump_root

  # Get miq_request from root
  miq_request = $evm.root['miq_request']
  raise "miq_request missing" if miq_request.nil?
  log(:info, "#{@method} - Detected Request:<#{miq_request.id}> with Approval State:<#{miq_request.approval_state}>")

  # Override the default appliance IP Address below
  appliance = nil
  appliance ||= $evm.object['miq_server_hostname']

  # Get incoming message or set it to default if nil
  msg = miq_request.resource.message || "Request pending"

  # Check to see which state machine called this method
  if msg.downcase.include?('quota')
    provisionRequestApproval = false
  else
    provisionRequestApproval = true
  end

  # Email Requester
  emailrequester(miq_request, appliance, msg, provisionRequestApproval)

  # Email Approver
  emailapprover(miq_request, appliance, msg, provisionRequestApproval)

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
