#
# The status
# - has a name and a description
class TaskStatus < ActiveRecord::Base
  # Model associations
  has_many :tasks

  scope :not_submitted,     -> { TaskStatus.find(1) }
  scope :complete,          -> { TaskStatus.find(2) }
  scope :need_help,         -> { TaskStatus.find(3) }
  scope :working_on_it,     -> { TaskStatus.find(4) }
  scope :fix_and_resubmit,  -> { TaskStatus.find(5) }
  scope :fix_and_include,   -> { TaskStatus.find(6) }
  scope :redo,              -> { TaskStatus.find(7) }
  scope :discuss,           -> { TaskStatus.find(8) }
  scope :ready_to_mark,     -> { TaskStatus.find(9) }

  def self.status_for_name(name)
    case name.downcase.strip
      when "complete"         then TaskStatus.complete
      when "fix_and_resubmit" then TaskStatus.fix_and_resubmit
      when "fix and resubmit" then TaskStatus.fix_and_resubmit
      when "fix_and_include"  then TaskStatus.fix_and_include
      when "fix and include"  then TaskStatus.fix_and_include
      when "redo"             then TaskStatus.redo
      when "need_help"        then TaskStatus.need_help
      when "need help"        then TaskStatus.need_help
      when "working_on_it"    then TaskStatus.working_on_it
      when "working on it"    then TaskStatus.working_on_it
      when "discuss"          then TaskStatus.discuss
      when "ready to mark"    then TaskStatus.ready_to_mark
      when "ready_to_mark"    then TaskStatus.ready_to_mark
      else                    TaskStatus.not_submitted
    end
  end

  def status_key
    case name
      when "Complete"         then :complete
      when "Not Submitted"    then :not_submitted
      when "Fix and Resubmit" then :fix_and_resubmit
      when "Fix and Include"  then :fix_and_include
      when "Redo"             then :redo
      when "Need Help"        then :need_help
      when "Working On It"    then :working_on_it
      when "Discuss"          then :discuss
      when "Ready to Mark"    then :ready_to_mark
      else :not_submitted
    end
  end

end