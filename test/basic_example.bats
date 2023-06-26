log_to_stdout() {
  local message="$1"

  # if no message is provided, redirect stdout to fd 3
  if [[ -z "$message" ]]; then
    cat - >&3
  fi
  echo "$message" >&3
}

setup() {
	# Load test helpers
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	# get the containing directory of this file
	# use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
	# as those will point to the bats executable's location or the preprocessed file respectively
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	# make executables in src/ visible to PATH
	PATH="$DIR/..:$PATH"

	# Set example dir
  EXAMPLE_DIR="$DIR/../examples/basic_example"
}

teardown() {
  log_to_stdout "Running vagrant destroy"
	cd "$EXAMPLE_DIR"
	vagrant destroy -f

  # Remove vagrantize-docker.sh script from docker build context
  rm "$EXAMPLE_DIR/vagrantize-docker.sh"
}

@test "can run vagrant up and ssh into container" {

  cd "$EXAMPLE_DIR"

  # Copy vagrantize-docker.sh script to docker build context
  cp "$DIR/../vagrantize-docker.sh" "$EXAMPLE_DIR/vagrantize-docker.sh"
  
  log_to_stdout "Running vagrant up"

  # run vagrant up
  vagrant up | log_to_stdout

  log_to_stdout "SSHing into container"
  run vagrant ssh --command "echo hello_world"
  assert_success
  assert_output --partial "hello_world"
}

