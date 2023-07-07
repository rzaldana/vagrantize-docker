.PHONY: test

vagrantize-docker.bash: ./src/vagrantize-docker.sh ./src/lib/*
	make_scripts/build.bash "./src/vagrantize-docker.sh" "./vagrantize-docker.bash"

test: ./vagrantize-docker.bash
	#./test/bats/bin/bats ./test/basic_example.bats
	./test/bats/bin/bats ./test/custom_user.bats

