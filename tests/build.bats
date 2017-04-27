#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

# export DOCKER_COMPOSE_STUB_DEBUG=/dev/stdout
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/stdout
# export BATS_MOCK_TMPDIR=$PWD

@test "Build without a repository" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD=myservice
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_BUILD_NUMBER=1

  stub docker-compose \
    "-f docker-compose.yml -p buildkite1111 -f docker-compose.buildkite-1-override.yml build myservice : echo built myservice"

  run $PWD/hooks/command

  unstub docker-compose
  assert_success
  assert_output --partial "built myservice"
}

@test "Build with a repository" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD=myservice
  export BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY=my.repository/llamas
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_BUILD_NUMBER=1

  stub docker-compose \
    "-f docker-compose.yml -p buildkite1111 -f docker-compose.buildkite-1-override.yml build myservice : echo built myservice" \
    "-f docker-compose.yml -p buildkite1111 -f docker-compose.buildkite-1-override.yml push myservice : echo pushed myservice" \

  stub buildkite-agent \
    "meta-data set docker-compose-plugin-built-image-tag-myservice my.repository/llamas:test-myservice-build-1 : echo set image metadata 0" \
    "meta-data set docker-compose-plugin-built-image-tag-0 myservice : echo set key metadata 0 " \
    "meta-data set docker-compose-plugin-built-image-count 1 : echo set image count"

  run $PWD/hooks/command

  assert_success
  assert_output --partial "built myservice"
  assert_output --partial "pushed myservice"
  assert_output --partial "set image metadata 0"
  assert_output --partial "set key metadata 0"
  assert_output --partial "set image count"
  unstub docker-compose
  unstub buildkite-agent
}

@test "Build with a repository and multiple services" {
  export BUILDKITE_JOB_ID=1112
  export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD_0=myservice1
  export BUILDKITE_PLUGIN_DOCKER_COMPOSE_BUILD_1=myservice2
  export BUILDKITE_PLUGIN_DOCKER_COMPOSE_IMAGE_REPOSITORY=my.repository/llamas
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_BUILD_NUMBER=1

  stub docker-compose \
    "-f docker-compose.yml -p buildkite1112 -f docker-compose.buildkite-1-override.yml build myservice1 myservice2 : echo built all services" \
    "-f docker-compose.yml -p buildkite1112 -f docker-compose.buildkite-1-override.yml push myservice1 myservice2 : echo pushed all services" \

  stub buildkite-agent \
    "meta-data set docker-compose-plugin-built-image-tag-myservice1 my.repository/llamas:test-myservice1-build-1 : echo set image metadata 0" \
    "meta-data set docker-compose-plugin-built-image-tag-0 myservice1 : echo set key metadata 0" \
    "meta-data set docker-compose-plugin-built-image-tag-myservice2 my.repository/llamas:test-myservice2-build-1 : echo set image metadata 1" \
    "meta-data set docker-compose-plugin-built-image-tag-1 myservice2 : echo set key metadata 1" \
    "meta-data set docker-compose-plugin-built-image-count 2 : echo set image count"

  run $PWD/hooks/command

  assert_success
  assert_output --partial "built all services"
  assert_output --partial "pushed all services"
  assert_output --partial "set image metadata 0"
  assert_output --partial "set key metadata 0"
  assert_output --partial "set image metadata 1"
  assert_output --partial "set key metadata 1"
  assert_output --partial "set image count"
  unstub docker-compose
  unstub buildkite-agent
}