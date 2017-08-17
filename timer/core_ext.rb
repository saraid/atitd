class Fixnum
  def egypt
    ATITD::EgyptTime::ProtoDuration.new(self)
  end

  def teppy
    ATITD::TeppyTime::ProtoDuration.new(self)
  end
end
