class Deploy < ActiveRecord::Base
  include BelongsToCommit

  belongs_to :project
  belongs_to :user

  validates :project_id, :environment_name, presence: true

  default_scope { order("completed_at DESC") }

  before_save :identify_deployer, if: :deployer
  after_save :notify_if_completed


  class << self
    def completed
      where arel_table[:completed_at].not_eq(nil)
    end

    def to_environment(environment_name)
      where(environment_name: environment_name)
    end
    alias :to :to_environment

    def before(time)
      where arel_table[:completed_at].lt(time)
    end

    def environments
      reorder(nil).pluck "DISTINCT environment_name"
    end
  end


  def commits
    @commits ||= find_commits
  end

  def previous_deploy
    @previous_deploy ||= project.deploys
      .completed
      .to(environment_name)
      .before(completed_at || Time.now)
      .first
  end

  def completed?
    completed_at.present?
  end

  def succeeded?
    successful?
  end

  def failed?
    !successful?
  end

  def environment
    environment_name
  end

  def environment_name=(value)
    super value.downcase
  end

  def output_stream
    @output_stream ||= OutputStream.new(self)
  end

  def date
    completed_at.to_date
  end

  def url
    "https://#{Houston.config.host}/projects/#{project.slug}/deploys/#{id}"
  end



private

  def find_commits
    return [] unless sha
    return [] unless previous_deploy
    project.commits.between(previous_deploy.sha, sha)
  end

  def identify_deployer
    self.user = User.find_by_email_address(deployer)
  end

  def notify_if_completed
    if just_completed?
      update_column :duration, completed_at - created_at if duration.nil?
      if successful?
        Houston.observer.fire "deploy:succeeded", deploy: self
      else
        Houston.observer.fire "deploy:failed", deploy: self
      end
      Houston.observer.fire "deploy:completed", deploy: self
    end
  end

  def just_completed?
    completed_at_changed? && completed?
  end

end
