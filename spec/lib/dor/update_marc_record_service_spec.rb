require 'spec_helper'

describe Dor::UpdateMarcRecordService do
  before :all do
    @fixtures = './spec/fixtures'
  end

  describe '.push_symphony_record' do
    pending
  end

  describe '.generate_symphony_record' do
    it 'should generate an empty string for a druid object without catkey' do
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'

      item = Dor::Item.new
      collection = double(Dor::Collection.new)
      identity_metadata_xml = double(String)

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_3)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111',
        catkey: '12345678'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'identityMetadata' => identity_metadata_xml }
      )

      release_data = { 'Searchworks' => { 'release' => true } }
      allow(item).to receive(:released_for).and_return(release_data)
      allow(collection).to receive(:released_for).and_return(release_data)

      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_record).to eq('')
    end
    it 'should generate symphony record for a item object with catkey' do
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'

      item = Dor::Item.new
      collection = Dor::Collection.new
      identity_metadata_xml = double(String)
      content_metadata_xml = double(String)

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_1)
      )

      allow(content_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_content_metadata_1)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111'
      )

      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection],
        datastreams: { 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml }
      )

      release_data = { 'Searchworks' => { 'release' => true } }
      allow(item).to receive(:released_for).and_return(release_data)

      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.generate_symphony_record).to eq("8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111::Collection label")
    end

    it 'should generate symphony record for a collection object with catkey' do
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'

      collection = Dor::Collection.new
      identity_metadata_xml = double(String)
      content_metadata_xml = double(String)

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_2)
      )

      allow(identity_metadata_xml).to receive(:tag).and_return('Project : Batchelor Maps : Batch 1')
      allow(content_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_content_metadata_2)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'aa111aa1111',
        collections: [],
        datastreams: { 'identityMetadata' => identity_metadata_xml, 'contentMetadata' => content_metadata_xml }
      )

      release_data = { 'Searchworks' => { 'release' => true } }
      allow(collection).to receive(:released_for).and_return(release_data)

      updater = Dor::UpdateMarcRecordService.new(collection)
      expect(updater.generate_symphony_record).to eq("8832162\taa111aa1111\t.856. 41|uhttp://purl.stanford.edu/aa111aa1111|xSDR-PURL|xcollection|xfile:aa111aa1111%2Fwt183gy6220_00_0001.jp2")
    end
  end

  describe '.write_symphony_record' do
    xit 'should write the symphony record to the symphony directory' do
      d = Dor::Item.new
      updater = Dor::UpdateMarcRecordService.new(d)
      updater.instance_variable_set(:@druid_id, 'aa111aa1111')
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr-purl"
      Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
      updater.write_symphony_record 'aaa'

      expect(Dir.glob("#{@fixtures}/sdr-purl/sdr-purl-aa111aa1111-??????????????").empty?).to be false
    end

    it 'should do nothing if the symphony record is empty' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('aa111aa1111')
      updater = Dor::UpdateMarcRecordService.new(d)
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr-purl"
      updater.write_symphony_record ''

      expect(Dir.glob("#{@fixtures}/sdr-purl/sdr-purl-aa111aa1111-??????????????").empty?).to be true
    end

    it 'should do nothing if the symphony record is nil' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('aa111aa1111')
      updater = Dor::UpdateMarcRecordService.new(d)
      Dor::Config.release.symphony_path = "#{@fixtures}/sdr-purl"
      updater.write_symphony_record ''

      expect(Dir.glob("#{@fixtures}/sdr-purl/sdr-purl-aa111aa1111-??????????????").empty?).to be true
    end

    after :each do
      FileUtils.rm_rf("#{@fixtures}/sdr-purl/.")
    end
  end

  describe '.catkey' do
    it 'should return catkey from a valid identityMetadata' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).exactly(3).times.and_return({'identityMetadata' => identity_metadata_ds})
      expect(d).to receive(:identityMetadata).and_return(identity_metadata_ds)
      expect(identity_metadata_ds).to receive(:ng_xml).twice.and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.ckey(d)).to eq('8832162')
    end

    it 'should return nil for an identityMetadata without catkey' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).exactly(3).times.and_return({'identityMetadata' => identity_metadata_ds})
      expect(d).to receive(:identityMetadata).and_return(identity_metadata_ds)
      expect(identity_metadata_ds).to receive(:ng_xml).twice.and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.ckey(d)).to be_nil
    end
  end

  describe '.object_type' do
    it 'should return object_type from a valid identityMetadata' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.object_type).to eq('|xitem')
    end

    it 'should return an empty x subfield for identityMetadata without object_type' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.object_type).to eq('|x')
    end
  end

  describe '.barcode' do
    it 'should return barcode from a valid identityMetadata' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_1)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.barcode).to eq('|xbarcode:36105216275185')
    end

    it 'should return an empty x subfield for identityMetadata without barcode' do
      d = double(Dor::Item)
      identity_metadata_ng_xml = Nokogiri::XML(build_identity_metadata_3)
      identity_metadata_ds = double(Dor::IdentityMetadataDS)

      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:datastreams).and_return({'identityMetadata' => identity_metadata_ds})
      expect(identity_metadata_ds).to receive(:ng_xml).and_return(identity_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.barcode).to be nil
    end
  end

  describe '.file_id' do
    it 'should return file_id from a valid contentMetadata' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_1)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('bb111bb2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:bb111bb2222%2Fwt183gy6220_00_0001.jp2')
    end

    it 'should return an empty x subfield for contentMetadata without file_id' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_3)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('aa111aa2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq(nil)
    end

    it 'should return correct file_id from a valid contentMetadata  with resource type = image' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_4)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('bb111bb2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:bb111bb2222%2Fwt183gy6220_00_0001.jp2')
    end

    it 'should return correct file_id from a valid contentMetadata with resource type = page' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_5)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('aa111aa2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:aa111aa2222%2Fwt183gy6220_00_0002.jp2')
    end

    # Added thumb based upon recommendation from Lynn McRae for future use
    it 'should return correct file_id from a valid contentMetadata with resource type = thumb' do
      d = double(Dor::Item)
      content_metadata_ng_xml = Nokogiri::XML(build_content_metadata_6)
      content_metadata_ds = double(Dor::ContentMetadataDS)

      expect(d).to receive(:id).and_return('bb111bb2222')
      expect(d).to receive(:datastreams).exactly(4).times.and_return({'contentMetadata' => content_metadata_ds})
      expect(content_metadata_ds).to receive(:ng_xml).twice.and_return(content_metadata_ng_xml)

      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.file_id).to eq('|xfile:bb111bb2222%2Fwt183gy6220_00_0002.jp2')
    end
  end

  describe '.get_856_cons' do
    it 'should return a valid sdrpurl constant' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_856_cons).to eq('.856.')
    end
  end

  describe '.get_1st_indicator' do
    it 'should return 4' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_1st_indicator).to eq('4')
    end
  end

  describe '.get_2nd_indicator' do
    it 'should return 1' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_2nd_indicator).to eq('1')
    end
  end

  describe '.get_u_field' do
    it 'should return valid purl url' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('aa111aa1111')
      updater = Dor::UpdateMarcRecordService.new(d)
      Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
      expect(updater.get_u_field).to eq('|uhttp://purl.stanford.edu/aa111aa1111')
    end
  end

  describe '.get_x1_sdrpurl_marker' do
    it 'should return a valid sdrpurl constant' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_x1_sdrpurl_marker).to eq('|xSDR-PURL')
    end
  end

  describe '.get_x2_collection_info' do
    it 'should return an empty string for an object without collection' do
      d = double(Dor::Item)
      expect(d).to receive(:id).and_return('')
      expect(d).to receive(:collections).and_return([])
      updater = Dor::UpdateMarcRecordService.new(d)
      expect(updater.get_x2_collection_info).to be_empty
    end

    it 'should return an empty string for a collection object' do
      c = double(Dor::Collection)
      expect(c).to receive(:id).and_return('')
      expect(c).to receive(:collections).and_return([])
      updater = Dor::UpdateMarcRecordService.new(c)
      expect(updater.get_x2_collection_info).to be_empty
    end

    it 'should return the appropriate information for a collection object' do
      item = double(Dor::Item.new)
      collection = Dor::Collection.new
      identity_metadata_xml = String

      allow(identity_metadata_xml).to receive_messages(
        ng_xml: Nokogiri::XML(build_identity_metadata_2)
      )

      allow(collection).to receive_messages(
        label: 'Collection label',
        id: 'cc111cc1111',
        datastreams: { 'identityMetadata' => identity_metadata_xml }
      )
      allow(item).to receive_messages(
        id: 'aa111aa1111',
        collections: [collection]
      )
      updater = Dor::UpdateMarcRecordService.new(item)
      expect(updater.get_x2_collection_info).to eq('|xcollection:cc111cc1111:8832162:Collection label')
    end
  end

  describe 'Released to Searchworks' do
    it 'should return true if release_data tag has release to=SW and value is true' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_1))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'Searchworks' => { 'release' => true } }
      allow(dor_item).to receive(:released_for).and_return(release_data)
      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be true
    end
    it 'should return false if release_data tag has release to=SW and value is false' do
      identity_metadata_xml = double('Identity Metadata', ng_xml: Nokogiri::XML(build_identity_metadata_2))
      dor_item = double('Dor Item', id: 'aa111aa1111', identityMetadata: identity_metadata_xml)
      release_data = { 'Searchworks' => { 'release' => false } }
      allow(dor_item).to receive(:released_for).and_return(release_data)

      updater = Dor::UpdateMarcRecordService.new(dor_item)
      expect(updater.released_to_Searchworks).to be false
    end
  end

  def build_identity_metadata_1
    '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb987ch8177</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="barcode">36105216275185</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15</tag>
  <release displayType="image" release="true" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">true</release>
</identityMetadata>'
  end

  def build_identity_metadata_2
    '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb987ch8177</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>collection</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
  <release displayType="image" release="false" to="Searchworks" what="collection" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
  </identityMetadata>'
  end

  def build_identity_metadata_3
    '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb987ch8177</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
</identityMetadata>'
  end

  def build_identity_metadata_4
    '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb987ch8177</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="barcode">36105216275185</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.1</tag>
  <release displayType="image" release="false" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
</identityMetadata>'
  end

  def build_release_data_1
    '<release_data>
<release to="Searchworks">true</release>
</release_data>'
  end

  def build_release_data_2
    '<release_data>
<release to="Searchworks">false</release>
</release_data>'
  end

  def build_content_metadata_1
    '<contentMetadata objectId="wt183gy6220" type="map">
<resource id="wt183gy6220_1" sequence="1" type="image">
<label>Image 1</label>
<file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
</contentMetadata>'
  end

  def build_content_metadata_2
    '<contentMetadata objectId="wt183gy6220">
<resource id="wt183gy6220_1" sequence="1" type="image">
<label>Image 1</label>
<file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_2" sequence="2" type="image">
<label>Image 2</label>
<file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
</contentMetadata>'
  end

  def build_content_metadata_3
    '<contentMetadata objectId="wt183gy6220">
</contentMetadata>'
  end

  def build_content_metadata_4
    '<contentMetadata objectId="wt183gy6220">
<resource id="wt183gy6220_1" sequence="1" type="image">
<label>PDF 1</label>
<file id="wt183gy6220.pdf" mimetype="application/pdf" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_1" sequence="2" type="image">
<label>Image 1</label>
<file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_2" sequence="3" type="image">
<label>Image 2</label>
<file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
</contentMetadata>'
  end

  def build_content_metadata_5
    '<contentMetadata objectId="wt183gy6220">
<resource id="wt183gy6220_1" sequence="1" type="image">
<label>PDF 1</label>
<file id="wt183gy6220.pdf" mimetype="application/pdf" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_2" sequence="2" type="page">
<label>Page 1</label>
<file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_1" sequence="3" type="page">
<label>Page 2</label>
<file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
</contentMetadata>'
  end

  # Added thumb based upon recommendation from Lynn McRae for future use
  def build_content_metadata_6
    '<contentMetadata objectId="wt183gy6220">
<resource id="wt183gy6220_1" sequence="1" type="image">
<label>PDF 1</label>
<file id="wt183gy6220.pdf" mimetype="application/pdf" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_2" sequence="2" type="thumb">
<label>Page 1</label>
<file id="wt183gy6220_00_0002.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
<resource id="wt183gy6220_1" sequence="3" type="page">
<label>Page 2</label>
<file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
<imageData width="4531" height="3715"/>
</file>
</resource>
</contentMetadata>'
  end
end
