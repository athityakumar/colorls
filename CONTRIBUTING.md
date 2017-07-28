# Contribution guidelines

First of all, thanks for thinking of contributing to this project. :smile:

Before sending a Pull Request, please make sure that you're assigned the task on a GitHub issue.

- If a relevant issue already exists, discuss on the issue and get it assigned to yourself on GitHub.
- If no relevant issue exists, open a new issue and get it assigned to yourself on GitHub.

Please proceed with a Pull Request only after you're assigned. It'd be sad if your Pull Request (and your hardwork) isn't accepted just because it isn't idealogically compatible.

# Developing the gem

1. Install with

    ```sh
    git clone https://github.com/athityakumar/colorls
    cd colorls
    gem install bundler
    bundle install
    ```

2. Make your changes in a different git branch (say, `add-new-flag`). These changes can be

    - adding better icons to [YAML files](lib/yaml/)
    - adding more flag options to the ruby gem.

3. (Optional) To test whether `colorls` executable is working properly, do 
    ```sh
    rake install
    ```
    Then install the gem file in the folder `pkg`. After that to use the new binary,
    ```sh
    colorls # start using colorls
    ```

4. (Required for YAML file changes) These are the specifications for the YAML files -

    - `files.yaml`, `folders.yaml` : The keys are sorted alphabetically.
    - `file_aliases.yaml`, `folder_aliases.yaml` : The values are sorted alphabetically. For each set of keys mapping to a value, those set of keys are also sorted alphabetically.

5. Check before pushing

    ```sh
    bundle exec rubocop
    bundle exec rspec
    ```

6. (Required for new flags) Add command to `.travis.yml` file.
