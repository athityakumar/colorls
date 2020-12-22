# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ColorLS::Git do
  before(:all) do
    `echo` # initialize $CHILD_STATUS
    expect($CHILD_STATUS).to be_success
  end

  def git_status(*entries)
    StringIO.new entries.map { |line| "#{line}\u0000" }.join
  end

  context 'file in repository root' do
    it 'should return `M`' do
      allow(subject).to receive(:git_prefix).with('/repo/').and_return('')
      allow(subject).to receive(:git_subdir_status).and_yield(git_status(' M foo.txt'))

      expect(subject.status('/repo/')).to include('foo.txt' => Set['M'])
    end

    it 'should return `M`' do
      allow(subject).to receive(:git_prefix).with('/repo/').and_return('')
      allow(subject).to receive(:git_subdir_status).and_yield(git_status('?? foo.txt'))

      expect(subject.status('/repo/')).to include('foo.txt' => Set['??'])
    end
  end

  context 'file in subdir' do
    it 'should return `M` for subdir' do
      allow(subject).to receive(:git_prefix).with('/repo/').and_return('')
      allow(subject).to receive(:git_subdir_status).and_yield(git_status(' M subdir/foo.txt'))

      expect(subject.status('/repo/')).to include('subdir' => Set['M'])
    end

    it 'should return `M` and `D` for subdir' do
      allow(subject).to receive(:git_prefix).with('/repo/').and_return('')
      allow(subject).to receive(:git_subdir_status).and_yield(git_status(' M subdir/foo.txt', 'D  subdir/other.c'))

      expect(subject.status('/repo/')).to include('subdir' => Set['M', 'D'])
    end
  end
end
