module UniqueAdd

  def add(relation)
    self << relation unless exists?(relation.id)
  end

end
