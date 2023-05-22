class Array

  def chunk( pieces = 2 )
    return self if pieces <= 0

    len    = self.length
    mid    = len / pieces
    chunks = []
    start  = 0

    1.upto( pieces ) do |i|
      last = start + mid
      last = last - 1 unless len % pieces >= i
      chunks << self[ start..last ] || []
      start = last + 1
    end

    chunks
  end
end
