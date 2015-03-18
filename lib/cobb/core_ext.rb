class Hash
    def except(*keys)
        reject{|k,v| keys.include?(k)}
    end
end
