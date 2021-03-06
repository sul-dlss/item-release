require 'spec_helper'

describe Dor::Release::Item do
  before do
    @druid = 'oo000oo0001'
    @item = Dor::Release::Item.new(druid: @druid, skip_heartbeat: true) # skip heartbeat check for dor-fetcher
    @n = 0

    # setup doubles and mocks so we can stub out methods and not make actual dor, webservice or workflow calls
    @client = instance_double(DorFetcher::Client)
    @response = { 'items' => ['returned_members'], 'sets' => ['returned_sets'], 'collections' => ['returned_collections'] }
    allow(@client).to receive(:get_collection).and_return(@response)
    @item.fetcher = @client

    @dor_object = instance_double(Dor::Item)
    allow(Dor).to receive(:find).and_return(@dor_object)
    allow(Dor::WorkflowObject).to receive(:initial_workflow).with(Dor::Config.release.workflow_name).and_return(true)
    allow(Dor::WorkflowObject).to receive(:initial_repo).with(Dor::Config.release.workflow_name).and_return(true)
  end

  it 'initializes' do
    expect(@item.druid).to eq @druid
  end

  it 'calls Dor.find, but only once' do
    expect(Dor).to receive(:find).with(@druid).and_return(@dor_object).once
    while @n < 3
      expect(@item.object).to eq @dor_object
      @n += 1
    end
  end

  it 'returns false for republish_needed' do
    expect(@item.republish_needed?).to be_falsey
  end

  it 'calls dor-fetcher-client to get the members, but only once' do
    expect(@item.fetcher).to receive(:get_collection).once
    while @n < 3
      expect(@item.members).to eq @response
      @n += 1
    end
  end

  it 'gets the right value for item_members' do
    expect(@item.item_members).to eq @response['items']
  end

  it 'gets the right value for sub_collections' do
    expect(@item.sub_collections).to eq @response['sets'] + @response['collections']
  end

  it 'adds the workflow for a collection' do
    expect(Dor::Config.workflow.client).to receive(:create_workflow).with(Dor::WorkflowObject.initial_repo(Dor::Config.release.workflow_name), @druid, Dor::Config.release.workflow_name, Dor::WorkflowObject.initial_workflow(Dor::Config.release.workflow_name), {}).once
    Dor::Release::Item.add_workflow_for_collection(@druid)
  end

  it 'adds the workflow for an item' do
    expect(Dor::Config.workflow.client).to receive(:create_workflow).with(Dor::WorkflowObject.initial_repo(Dor::Config.release.workflow_name), @druid, Dor::Config.release.workflow_name, Dor::WorkflowObject.initial_workflow(Dor::Config.release.workflow_name), {}).once
    Dor::Release::Item.add_workflow_for_item(@druid)
  end

  it 'makes a webservice call for updating_marc_records' do
    stub_request(:post, 'https://example.com/dor/v1/objects/oo000oo0001/update_marc_record')
      .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip, deflate', 'Authorization' => 'Basic VVNFUk5BTUU6UEFTU1dPUkQ=' })
      .to_return(status: 201, body: '', headers: {})
    # TODO: confirm RestClient call is made?
    expect(@item.update_marc_record).to eq(201)
  end

  it 'returns correct object types for an item' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>item</objectType></identityMetadata>'))
    expect(@item.is_item?).to be_truthy
    expect(@item.is_collection?).to be_falsey
    expect(@item.is_set?).to be_falsey
    expect(@item.is_apo?).to be_falsey
  end

  it 'returns correct object types for a set' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>set</objectType></identityMetadata>'))
    expect(@item.is_item?).to be_falsey
    expect(@item.is_collection?).to be_falsey
    expect(@item.is_set?).to be_truthy
    expect(@item.is_apo?).to be_falsey
  end

  it 'returns correct object types for a collection' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>collection</objectType></identityMetadata>'))
    expect(@item.is_item?).to be_falsey
    expect(@item.is_collection?).to be_truthy
    expect(@item.is_set?).to be_falsey
    expect(@item.is_apo?).to be_falsey
  end

  it 'returns correct object types for an apo' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>adminPolicy</objectType></identityMetadata>'))
    expect(@item.is_item?).to be_falsey
    expect(@item.is_collection?).to be_falsey
    expect(@item.is_set?).to be_falsey
    expect(@item.is_apo?).to be_truthy
  end
end
