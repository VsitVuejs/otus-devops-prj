# otus-devops-prj
Учебный проект по развертыванию микросервисного приложения 
(2 приложения на python, mongodb, rabbit) на кластере kubernetes с мониторином(прометей) и логированием(loki) в Yandex Cloud.

В папке terraform/cluster \
Нужно заполнить переменные окружения.\
cloud_id    - id яндекс облака\
folder_id   - id директории яндекс облака\
yc_token    - токен для доступа\
loki_storage_size - размер хранилища для loki

выполнить:\
terraform init\
terraform apply

Будет развернут Kubernetes с мониторингом (прометей), ингресс контроллером(nginx) и логированием (loki)


В папке terraform/app-crawler \
Нужно заполнить переменные окружения.\
cloud_id    - id яндекс облака\
folder_id   - id директории яндекс облака\
yc_token    - токен для доступа\
basic_auth_pass    - пароль для базовой авторизации к сервису (логин будет user)\
docker_username - данные для авторизации в докер хранилище \
docker_password - пароль для авторизации в докер хранилище\
rmq_username - произвольные логин/пароль для rabbita\
rmq_password \
cluster_id - id kubernetes кластера

выполнить:\
terraform init\
terraform apply

Будет развернуто приложение для поиска на сайтах.

Для работы github actions необходимо заполнить переменные окружения.
