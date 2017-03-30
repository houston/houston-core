class RemoveAntecedentsFromVersionsOfTickets < ActiveRecord::Migration[5.0]
  class Version < ActiveRecord::Base; end

  def up
    versions = Version.where("modifications like '%!ruby/object:TicketAntecedent%'")
    pbar = ProgressBar.new("progress", versions.count)
    versions.pluck(:id, :modifications).each do |id, modifications|
      new_modifications = modifications.except("antecedents")
      if new_modifications.empty?
        Version.where(id: id).delete_all
      else
        Version.where(id: id).update_all(modifications: new_modifications)
      end
      pbar.inc
    end
    pbar.finish

    versions = Version.where("modifications like '%!ruby/object:TicketTag%'")
    pbar = ProgressBar.new("progress", versions.count)
    versions.pluck(:id, :modifications).each do |id, modifications|
      change = modifications["tags"]
      new_modifications = modifications.merge("tags" => [change[0].map(&:to_s), change[1].map(&:to_s)])
      Version.where(id: id).update_all(modifications: new_modifications)
      pbar.inc
    end
    pbar.finish
  end

end

class TicketAntecedent; end
class TicketTag
  attr_reader :name, :color

  def to_s
    "[#{name}](#{color})"
  end
end
