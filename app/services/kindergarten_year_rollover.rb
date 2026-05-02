class KindergartenYearRollover
  def initialize(new_year)
    @new_year = new_year
  end

  def execute(child_ids)
    return if child_ids.blank?
    Child.where(id: child_ids).find_each do |child|
      child.transfer_to(@new_year)
    end
  end
end
