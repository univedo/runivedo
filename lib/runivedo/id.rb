module Runivedo
  class Id
    include Comparable

    attr :owner_id, :id

    def initialize(owner_id, id)
      @owner_id = owner_id
      @id = id
    end

    def to_s
      @id.to_s
#      "[#{@owner_id}, #{@id}]"
    end

    def <=>(other)
      c = (@owner_id <=> other.owner_id)
      if c == 0
        @id <=> other.id
      else
        c
      end
    end
  end
end
