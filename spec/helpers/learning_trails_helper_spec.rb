require 'rails_helper'
include LearningTrailsHelper

RSpec.describe LearningTrailsHelper, type: :helper do
  before(:each) do
    Category.delete_all
    TopicLevel.delete_all
    Topic.delete_all
    Task.delete_all
    Goal.delete_all
    UserTask.delete_all
    UserGoal.delete_all
    User.delete_all

    category = Category.create(category: 'clean-code')
    topic = category.topics.create(
      name: 'legacy-code.md',
      summary: 'summary',
      path: 'clean-code/legacy-code.md',
      sha: 'df0a42d82a29077385b1adbe44a05b7552d4ae8f',
      size: 901,
      url: '',
      html_url: '',
      git_url: '',
      download_url: '',
      github_type: 'file'
    )

    level = topic.topic_levels.create(
      [
        { level_number: 1, version: 0 },
        { level_number: 2, version: 0 }
      ]
    )

    topic.references.create(
      [
        { content: 'ref 1' },
        { content: 'ref 2' }
      ]
    )

    TopicLevel.all.each do |topic_level|
      topic_level.tasks.create([{ content: 'number http://google.com) 1', version: 0 }])
      topic_level.goals.create([{ content: 'get thru it (/legacy-code.md) ', version: 0 }])
    end

    UserTask.create(
      [
        { user_id: 1, task_id: Task.all[0][:id] },
        { user_id: 1, task_id: Task.all[1][:id] }
      ]
    )

    UserReference.create(
      [
        { user_id: 1, reference_id: Reference.all[0][:id] },
        { user_id: 1, reference_id: Reference.all[1][:id]}
      ]
    )

    UserGoal.create(
      [
        { user_id: 1, goal_id: Goal.all[0][:id] },
        { user_id: 1, goal_id: Goal.all[1][:id] }
      ]
    )
  end

  after(:each) do
    Category.delete_all
    TopicLevel.delete_all
    Topic.delete_all
    Task.delete_all
    Goal.delete_all
    UserTask.delete_all
    UserGoal.delete_all
    User.delete_all
  end

  describe 'get_topic_json' do
    it 'returns the topic in a hash with levels/tasks/goals' do
      topic_id = Topic.first[:id]
      result = LearningTrailsHelper.get_topic_json(topic_id, 1)

      expect(result.class).to eq(Hash)
      expect(result['id']).to eq(topic_id)
      expect(Topic.all.count).to eq(1)
      expect(result['levels'].size).to eq(2)
      expect(result['levels'][0]['tasks'].length).to eq(1)
      expect(result['levels'][1]['tasks'].length).to eq(1)
      expect(result['levels'][0]['goals'].length).to eq(1)
      expect(result['levels'][1]['goals'].length).to eq(1)
      expect(result['levels'][0]['tasks'][0]['link']).to eq('http://google.com')
      expect(result['levels'][0]['goals'][0]['link']).to eq(nil)
      expect(result['references'].size).to eq(2)
      expect(result['references'][0].content).to eq('ref 1')
    end
  end

  unless ENV['TRAVIS']
    describe 'total_tasks' do
      it 'returns the number of tasks for a topic' do
        result = LearningTrailsHelper.total_tasks(Topic.first[:id], 1)
        expect(result).to eq(2)
      end
    end

    describe 'completed_tasks' do
      it 'returns the number of tasks completed for a topic' do
        result = LearningTrailsHelper.completed_tasks(Topic.first[:id], 1)
        expect(result).to eq(0)
      end
    end

    describe 'task_completion_percentage' do
      it 'returns the task completion percentage' do
        result = LearningTrailsHelper.task_completion_percentage(Topic.first[:id], 1)
        expect(result).to eq('0%')
      end

      it 'returns 0% if no tasks exists' do
        Task.delete_all
        result = LearningTrailsHelper.task_completion_percentage(Topic.first[:id], 1)
        expect(result).to eq('0%')
      end
    end
  end
end
