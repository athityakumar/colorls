
RSpec.describe "String#delete_prefix" do
  # back compat for Ruby < 2.5

  it "returns a copy of the string, with the given prefix removed" do
    expect('hello'.delete_prefix('hell')).to eq 'o'
    expect('hello'.delete_prefix('hello')).to eq ''
  end

  it "returns a copy of the string, when the prefix isn't found" do
    s = 'hello'
    r = s.delete_prefix('hello!')
    expect(r).not_to equal s
    expect(r).to be == s
    r = s.delete_prefix('ell')
    expect(r).not_to equal s
    expect(r).to be == s
    r = s.delete_prefix('')
    expect(r).not_to equal s
    expect(r).to be == s
  end

end
