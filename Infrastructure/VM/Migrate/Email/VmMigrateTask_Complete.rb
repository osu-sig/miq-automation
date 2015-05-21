###################################
#
# EVM Automate Method: VmMigrateTask_Complete
#
# Notes: This method sends an e-mail when the following event is raised:
#
# Events: VmMigrateTask_Complete
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
begin
  @method = 'VmMigrateTask_Complete'
  $evm.log("info", "===== EVM Automate Method: <#{@method}> Started")

  # Turn of verbose logging
  @debug = true

  # Look in the Root Object for the request
  miq_task = $evm.root['vm_migrate_task']
  miq_server = $evm.root['miq_server']

  $evm.log("info", "Inspecting miq_task: #{miq_task.inspect}") if @debug

  #
  # Exit method
  #
  $evm.log("info", "===== EVM Automate Method: <#{@method}> Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  $evm.log("error", "<#{@method}>: [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end