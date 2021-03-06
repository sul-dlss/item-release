require 'spec_helper'

describe Robots::DorRepo::Release::ReleasePublish do
  before do
    @druid = 'aa222cc3333'
    @work_item = instance_double(Dor::Item)
    @r = Robots::DorRepo::Release::ReleasePublish.new
  end

  it 'runs the robot, calling publish metadata on the dor item' do
    setup_release_item(@druid, :item, nil)
    expect(@dor_item).to receive(:publish_metadata).once
    @r.perform(@work_item)
  end
end
