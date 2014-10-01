module Moduler
  #
  # A Facade on top of a value.  This provides the basic Facade interface
  # (get, set, set?, coerce and coerce_out) that all facades conform to.
  #
  # A Facade could be an:
  # - hash interface on top of a struct or other object
  # - accessor (like hash[key]).
  # - transform that converts strings to symbols
  # - validator that checks "get.kind_of?"
  #
  # A few methods are assumed to be on the object:
  # +set(value) assumes +raw=(value)+.
  # +coerce_out+ also assumes that new(raw_value) exists.
  #
  module Facade
    def raw
      raise NotImplementedError
    end
    def raw=
      raise NotImplementedError
    end
    def has_raw?
      raise NotImplementedError
    end
  end
end
