class Hash
  def symbolize
    hash = self.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    hash.each do |k, v|
      hash[k] = v.symbolize if v.is_a? Hash
    end
    hash
  end

  def except(*keys)
    dup.except!(*keys)
  end

  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end
