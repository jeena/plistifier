gem "cfpropertylist", ">=2.0.9"

require 'plistifier/plist_encoding'
require 'rails_extensions'

Mime::Type.register "application/plist", :plist

ActionController::Base.param_parsers[Mime::Type.lookup("application/plist")] = lambda do |body|
  str = StringIO.new(body)
  plist = CFPropertyList::List.new({:data => str.string})
  CFPropertyList.native_types(plist.value)
end