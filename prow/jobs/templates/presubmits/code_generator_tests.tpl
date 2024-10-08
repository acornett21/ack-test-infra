  aws-controllers-k8s/code-generator:
  - name: unit-test
    decorate: true
    optional: false
    always_run: true
    annotations:
      karpenter.sh/do-not-evict: "true"
    spec:
      serviceAccountName: pre-submit-service-account
      containers:
      - image: {{printf "%s:%s" $.ImageContext.ImageRepo (index $.ImageContext.Images "unit-test") }}
        resources:
          limits:
            cpu: 2
            memory: "3072Mi"
          requests:
            cpu: 2
            memory: "3072Mi"
        command: ["make", "test"]
  - name: s3-olm-test
    decorate: true
    optional: true
    always_run: true
    annotations:
      karpenter.sh/do-not-evict: "true"
    extra_refs:
    - org: aws-controllers-k8s
      repo: runtime
      base_ref: main
      workdir: false
    - org: aws-controllers-k8s
      repo: test-infra
      base_ref: main
      workdir: false
    - org: aws-controllers-k8s
      repo: s3-controller
      base_ref: main
      workdir: false
    spec:
      serviceAccountName: pre-submit-service-account
      containers:
      - image: {{printf "%s:%s" $.ImageContext.ImageRepo (index $.ImageContext.Images "olm-test") }}
        resources:
          limits:
            cpu: 2
            memory: "1024Mi"
          requests:
            cpu: 2
            memory: "1024Mi"
        env:
        - name: SERVICE
          value: "s3"
        - name: ACK_GENERATE_OLM
          value: "true"
        command: ["make", "build-controller"]
  {{- range $_, $service := .Config.CodegenPresubmitServices }}
  - name: {{ $service }}-controller-test
    decorate: true
    optional: false
    always_run: true
    annotations:
      karpenter.sh/do-not-evict: "true"
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
      preset-test-config: "true"
    extra_refs:
    - org: aws-controllers-k8s
      repo: runtime
      base_ref: main
      workdir: false
    - org: aws-controllers-k8s
      repo: test-infra
      base_ref: main
      workdir: true
    - org: aws-controllers-k8s
      repo: {{ $service }}-controller
      base_ref: main
      workdir: true
    spec:
      serviceAccountName: pre-submit-service-account
      containers:
      - image: {{printf "%s:%s" $.ImageContext.ImageRepo (index $.ImageContext.Images "integration-test") }}
        resources:
          limits:
            cpu: 8
            memory: "3072Mi"
          requests:
            cpu: 8
            memory: "3072Mi"
        securityContext:
          privileged: true
        env:
        - name: SERVICE
          value: {{ $service }}
        {{ if contains $.Config.CarmTestServices $service }}
        - name: CARM_TESTS_ENABLED
          value: "true"
        {{ end -}}
        command: ["wrapper.sh", "bash", "-c", "./cd/core-validator/generate-test-controller.sh"]
{{ end }}