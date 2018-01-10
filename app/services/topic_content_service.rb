require 'open-uri'

# This module is specific to the format of the markdown in learning
# trails github repo. It is not intended to have any extended use.

module TopicContentService
  @regex = {
    references: Regexp.new(/#+\sOngoing\sReference/),
    level: Regexp.new(/#+\sLevel\s\d+/),
    bullets: Regexp.new(/\*\s/),
    goals: Regexp.new(/#+\sYou\sshould\sbe\sable\sto/),
    url: Regexp.new(/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/)
  }

  def save_topic_content(topic)
    version_exists = topic.lessons.exists?(version: topic.version)
    return if version_exists
    raw_content = get_raw_content(topic.download_url)
    content_and_references = raw_content.split(@regex[:references])
    if content_and_references.length > 1
      references_block = content_and_references[1]
      references = get_references(references_block)
      save_references(references, topic)
    end
    summary_and_levels = content_and_references[0].split(@regex[:level])
    save_topic_summary(summary_and_levels, topic)
    parse_and_save_levels(summary_and_levels, topic)
  end

  def get_references(references)
    references.strip.split(@regex[:bullets])
  end

  def save_references(references, topic)
    references.shift
    references.each do |ref|
      clean_ref = ref.strip
      lesson = topic.lessons.new(content: clean_ref)
      lesson.lesson_type = 'reference'
      lesson.level = 0
      lesson.version = topic.version
      lesson.save
    end
  end

  def save_topic_summary(summary_and_levels, topic)
    summary_and_topic = summary_and_levels[0]
    topic.summary = summary_and_topic.split(/\n\n/)[1]
    topic.save
  end

  def parse_and_save_levels(summary_and_levels, topic)
    summary_and_levels.shift
    summary_and_levels.each_with_index do |level, index|
      level_number = index + 1
      goals, tasks = get_tasks_and_goals(level)
      remove_empty_values(goals, tasks)
      save_tasks(tasks, level_number, topic)
      save_goals(goals, level_number, topic)
    end
  end

  def get_tasks_and_goals(level)
    level_tasks_and_goals = level.split(@regex[:goals])
    tasks = []
    goals = []

    unless level_tasks_and_goals.empty?
      tasks = level_tasks_and_goals[0].strip.split(@regex[:bullets])
    end

    if level_tasks_and_goals.size > 1
      goals = level_tasks_and_goals[1].strip.split(@regex[:bullets])
    end
    [goals, tasks]
  end

  def remove_empty_values(goals, tasks)
    tasks.shift
    goals.shift
  end

  def save_goals(goals, level_number, topic)
    goals.each do |goal|
      clean_goal = goal.strip
      lesson = topic.lessons.new(content: clean_goal)
      lesson.lesson_type = 'goal'
      lesson.level = level_number
      lesson.version = topic.version
      lesson.save
    end
  end

  def save_tasks(tasks, level_number, topic)
    tasks.each do |_task|
      clean_task = _task.strip
      lesson = topic.lessons.new(content: clean_task)
      lesson.level = level_number
      lesson.lesson_type = 'task'
      task_link = clean_task[@regex[:url]]
      begin
        target_page = MetaInspector.new(task_link)
        lesson.link_image = target_page.images.favicon
        lesson.link_summary = target_page.best_description
      rescue
        lesson.link_image = ''
        lesson.link_summary = ''
      ensure
        lesson.version = topic.version
        lesson.save
      end
    end
  end

  def get_raw_content(topic_raw_url)
    uri = URI.parse(topic_raw_url)
    uri.read
  end
end
