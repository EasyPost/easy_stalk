require 'spec_helper'

describe EasyStalk::DescendantTracking do

  specify "it remembers who it's children are" do
    class HelicopterDad
      include EasyStalk::DescendantTracking
    end
    expect(HelicopterDad.descendants).to be_empty

    class GoodKid < HelicopterDad; end
    expect(HelicopterDad.descendants).to eq [GoodKid]

    class YourKid; end
    expect(HelicopterDad.descendants).to eq [GoodKid]

    class BadKid < HelicopterDad; end
    expect(HelicopterDad.descendants).to eq [GoodKid, BadKid]
  end

end
