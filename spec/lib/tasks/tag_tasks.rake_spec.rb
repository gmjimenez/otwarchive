require "spec_helper"

describe "rake Tag:destroy_invalid_common_taggings" do
  it "deletes CommonTaggings with a missing child" do
    parent = create(:canonical_fandom)
    child = create(:character)
    common_tagging = CommonTagging.create(filterable: parent, common_tag: child)
    child.delete

    expect { subject.invoke }.not_to raise_exception
    expect { common_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes CommonTaggings with a missing parent" do
    parent = create(:canonical_fandom)
    child = create(:character)
    common_tagging = CommonTagging.create(filterable: parent, common_tag: child)
    parent.delete

    expect { subject.invoke }.not_to raise_exception
    expect { common_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes CommonTaggings with a non-canonical parent" do
    parent = create(:fandom)
    child = create(:character)
    common_tagging = CommonTagging.new(filterable: parent, common_tag: child)
    common_tagging.save(validate: false)

    expect { subject.invoke }.not_to raise_exception
    expect { common_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes CommonTaggings with mismatched types" do
    parent = create(:canonical_character)
    child = create(:fandom)
    common_tagging = CommonTagging.new(filterable: parent, common_tag: child)
    common_tagging.save(validate: false)

    expect { subject.invoke }.not_to raise_exception
    expect { common_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "doesn't delete valid CommonTaggings" do
    parent = create(:canonical_fandom)
    child = create(:character)
    common_tagging = CommonTagging.create(filterable: parent, common_tag: child)

    expect { subject.invoke }.not_to raise_exception
    expect { common_tagging.reload }.not_to raise_exception
  end
end

describe "rake Tag:destroy_invalid_meta_taggings" do
  it "deletes MetaTaggings with a missing child" do
    parent = create(:canonical_fandom)
    child = create(:canonical_fandom)
    meta_tagging = MetaTagging.create(meta_tag: parent, sub_tag: child)
    child.delete

    expect { subject.invoke }.not_to raise_exception
    expect { meta_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes MetaTaggings with a missing parent" do
    parent = create(:canonical_fandom)
    child = create(:canonical_fandom)
    meta_tagging = MetaTagging.create(meta_tag: parent, sub_tag: child)
    parent.delete

    expect { subject.invoke }.not_to raise_exception
    expect { meta_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes MetaTaggings with a non-canonical child" do
    parent = create(:canonical_fandom)
    child = create(:fandom)
    meta_tagging = MetaTagging.new(meta_tag: parent, sub_tag: child)
    meta_tagging.save(validate: false)

    expect { subject.invoke }.not_to raise_exception
    expect { meta_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes MetaTaggings with a non-canonical parent" do
    parent = create(:fandom)
    child = create(:canonical_fandom)
    meta_tagging = MetaTagging.new(meta_tag: parent, sub_tag: child)
    meta_tagging.save(validate: false)

    expect { subject.invoke }.not_to raise_exception
    expect { meta_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "deletes MetaTaggings with mismatched types" do
    parent = create(:canonical_character)
    child = create(:canonical_fandom)
    meta_tagging = MetaTagging.new(meta_tag: parent, sub_tag: child)
    meta_tagging.save(validate: false)

    expect { subject.invoke }.not_to raise_exception
    expect { meta_tagging.reload }.to raise_exception(ActiveRecord::RecordNotFound)
  end

  it "doesn't delete valid MetaTaggings" do
    parent = create(:canonical_fandom)
    child = create(:canonical_fandom)
    meta_tagging = MetaTagging.create(meta_tag: parent, sub_tag: child)

    expect { subject.invoke }.not_to raise_exception
    expect { meta_tagging.reload }.not_to raise_exception
  end
end

describe "rake Tag:reset_meta_tags" do
  let(:sub) { create(:canonical_fandom) }
  let(:meta) { create(:canonical_fandom) }

  it "deletes phantom inherited metatags" do
    MetaTagging.create(sub_tag: sub, meta_tag: meta, direct: false)

    expect(sub.meta_tags.reload).to include(meta)
    subject.invoke
    expect(sub.meta_tags.reload).not_to include(meta)
  end

  it "constructs missing inherited metatags" do
    mid = create(:canonical_fandom)
    mid.meta_tags << meta
    mid.sub_tags << sub
    sub.meta_tags.delete(meta)

    expect(sub.meta_tags.reload).not_to include(meta)
    subject.invoke
    expect(sub.meta_tags.reload).to include(meta)
  end
end

describe "rake Tag:reset_filters" do
  let(:sub) { create(:canonical_fandom) }
  let(:syn) { create(:fandom, merger: sub) }
  let(:meta) { create(:canonical_fandom) }
  let(:work) { create(:work, fandom_string: syn.name) }
  let(:extra) { create(:fandom) }

  before { sub.meta_tags << meta }

  it "adds missing inherited filters" do
    work.filters.delete(meta)
    subject.invoke
    expect(work.filters.reload).to include(meta)
    expect(work.direct_filters.reload).not_to include(meta)
  end

  it "adds missing direct filters" do
    work.filters.delete(sub)
    subject.invoke
    expect(work.filters.reload).to include(sub)
    expect(work.direct_filters.reload).to include(sub)
  end

  it "removes incorrect inherited filters" do
    work.filter_taggings.create(filter: extra, inherited: true)
    subject.invoke
    expect(work.filters.reload).not_to include(extra)
    expect(work.direct_filters.reload).not_to include(extra)
  end

  it "removes incorrect direct filters" do
    work.filter_taggings.create(filter: extra, inherited: false)
    subject.invoke
    expect(work.filters.reload).not_to include(extra)
    expect(work.direct_filters.reload).not_to include(extra)
  end
end
