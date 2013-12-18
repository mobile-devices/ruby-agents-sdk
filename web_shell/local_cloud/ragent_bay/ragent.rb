###################################################################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
###################################################################################################


$allow_non_protogen = true
$allow_protogen_fault = true

require 'active_support/all'


require_relative 'user_api/user_api_factory'
require_relative 'ragent_api/ragent_api'

require_relative 'ragent_api/sdk_stats'
require_relative 'ragent_api/punkabe'

require_relative 'agents_generated_source/protogen_generated'


# nowere apis
def crop_ref(ref, size)
  ref_str = "#{ref}"
  if ref_str.size <= size
    ref_str
  else
    ref_str.split(//).last(size).join('')
  end
end