TANYATEGUH_REPOSITORY=registry.bukalapak.io/bukalapak/tanyateguh
TANYATEGUH_VERSION=201804091745
TMP_DIR:=deploy/_output

release:
	git branch release-$(TANYATEGUH_VERSION)
	git push origin -u release-$(TANYATEGUH_VERSION)

docker-build:
	docker build -t $(TANYATEGUH_REPOSITORY):$(TANYATEGUH_VERSION) .

docker-push:
	docker push $(TANYATEGUH_REPOSITORY):$(TANYATEGUH_VERSION)
	docker push $(TANYATEGUH_REPOSITORY)

docker-all: docker-build docker-push

kube-prepare:
	@mkdir -p $(TMP_DIR)
	@sed "\
		s~\$$TANYATEGUH_REPOSITORY~$(TANYATEGUH_REPOSITORY)~g;\
		s~\$$TANYATEGUH_VERSION~$(TANYATEGUH_VERSION)~g;"\
		deploy/deployment.yml.tmpl > $(TMP_DIR)/deployment.yml

kube-create: kube-prepare
	kubectl create -f $(TMP_DIR)/deployment.yml

kube-replace: kube-prepare
	kubectl replace -f $(TMP_DIR)/deployment.yml
