# frozen_string_literal: true
require 'tempfile'

class TaskComment < ActiveRecord::Base
  include MimeCheckHelpers
  include TimeoutHelper
  include FileHelper

  belongs_to :task # Foreign key
  belongs_to :user
  has_one :unit, through: :task
  has_one :project, through: :task

  belongs_to :recipient, class_name: 'User'

  has_one :discussion_comment, class_name: 'DiscussionComment', required: false

  has_many :comments_read_receipts, class_name: 'CommentsReadReceipts', dependent: :destroy, inverse_of: :task_comment

  validates :task, presence: true
  validates :user, presence: true
  validates :recipient, presence: true
  validates :comment, length: { minimum: 0, maximum: 4095, allow_blank: true }

  # After create, mark as read by user creating
  after_create do
    mark_as_read(self.user)
  end

  # Delete action - before dependent association
  before_destroy :delete_associated_files

  def new_for?(user)
    CommentsReadReceipts.where(user: user, task_comment_id: self).empty?
  end

  def delete_associated_files
    FileUtils.rm attachment_path if File.exist? attachment_path
  end

  def serialize(user)
    {
      id: self.id,
      comment: self.comment,
      has_attachment: ["audio", "image", "pdf"].include?(self.content_type),
      type: self.content_type || "text",
      is_new: self.new_for?(user),
      author: {
        id: self.user.id,
        name: self.user.name,
        email: self.user.email
      },
      recipient: {
        id: self.recipient.id,
        name: self.recipient.name,
        email: self.user.email
      },
      created_at: self.created_at,
      recipient_read_time: self.time_read_by(self.recipient),
    }
  end

  def create_comment_read_receipt_entry(user)
    comment_read_receipt = CommentsReadReceipts.find_or_create_by(user: user, task_comment: self)
  end

  def comment
    return 'audio comment' if content_type == 'audio'
    return 'image comment' if content_type == 'image'
    return 'pdf document' if content_type == 'pdf'
    return 'discussion comment' if content_type == 'discussion'
    super
  end

  def attachment_path
    FileHelper.comment_attachment_path(self, attachment_extension)
  end

  def attachment_file_name
    "comment-#{id}#{attachment_extension}"
  end

  def add_attachment(file_upload)
    if content_type == 'audio'
      # On upload all audio comments are converted to wav
      temp = Tempfile.new(['comment', '.wav'])
      return false unless process_audio(file_upload.tempfile.path, temp.path)
      self.attachment_extension = '.wav'
      save
      FileUtils.mv temp.path, attachment_path
    elsif content_type == 'image'
      self.attachment_extension = if mime_type(file_upload.tempfile.path).starts_with?('image/gif')
                                    '.gif'
                                  else
                                    '.jpg'
                                  end
      save
      FileHelper.compress_image_to_dest(file_upload.tempfile.path, attachment_path)
    else
      self.attachment_extension = '.pdf'
      save
      FileHelper.compress_pdf(file_upload.tempfile.path)
      FileUtils.mv file_upload.tempfile.path, attachment_path
    end

    file_upload.tempfile.unlink

    true
  end

  def attachment_mime_type
    if attachment_extension == '.wav'
      'audio/wav; charset:binary'
    else
      mime_type(attachment_path)
    end
  end

  def remove_comment_read_entry(user)
    CommentsReadReceipts.delete_all(user: user, task_comment: self)
  end

  def mark_as_read(user, unit = self.unit)
    return if read_by?(user) # avoid propagating if not needed

    if user == project.main_tutor
      unit.staff.each do |staff_member|
        create_comment_read_receipt_entry(staff_member.user)
      end
    else
      create_comment_read_receipt_entry(user)
    end
  end

  def mark_as_unread(user)
    remove_comment_read_entry(user)
  end

  def read_by?(user)
    CommentsReadReceipts.find_by(user: user, task_comment: self).present?
  end

  def time_read_by(user)
    read_reciept = CommentsReadReceipts.find_by(user: user, task_comment: self)
    read_reciept&.created_at
  end

end
