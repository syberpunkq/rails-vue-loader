require 'digest'

module Sprockets::Vue::Utils
  module_function

  def node_regex(tag)
    %r(
    \<#{tag}
      (\s+lang=["'](?<lang>\w+)["'])?
      (?<scoped>\s+scoped)?
    \>
      (?<content>.+)
    \<\/#{tag}\>
    )mx
  end

  def scope_key(data)
    Digest::MD5.hexdigest data
  end
end
