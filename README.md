#Images

Скрипты и инструменты для создания образов (vm images, docker containers, vagrant boxes, etc), используемых в платформе и инфраструктуре _rbkmoney_.

## Prerequisities
### Vagrant box
На OS X платформе рекомендуется использовать _Vagrant rbkmoney dev box_

```
cd dev
vagrant up
vagrant ssh
cd /base_images/
```


### Docker hub
Перед созданием контейнеров рекомендуется авторизоваться в _docker hub_ и получить там доступ к __rbkmoney__ репозиториям.
Большинство `make` команд подразумевает использование готовых _приватных_ контейнеров __rbkmoney__. Только _scratch builds_ возможны без авторизации.
Для авторизации сессии в _docker hub_ надо выполнить команду `docker login`.

## Containers hierarchy
```
bootstrap
    service_base
        service_erlang
        service_go
        service_java
    host
```

## HowTo
### Build a container
Создать контейнер `<container>` на основе готового родительского контейнера, согласно _containers hierarchy_.
Последняя версия родительского контейнера скачивается из репозитория _rbkmoney_ на _docker hub_ (если локальная версия соответствует последней из _docker hub_, _docker_ использует её после проверки).

```
make <container>
```

Смотри список доступных значений `<container>` в __Containers hierarchy__.

### Build a container from scratch
Создать контейнер `<container>` с нуля, т.е. построить контейнер и все родительские контейнеры в иерархии.
Если какой-либо родительский контейнер уже строился локально, то он может быть взят из локального _docker image registry_
(если его зависимости не изменялись с последнего билда - стандартная логика `make`). `docker pull` использован не будет.

```
FROM_SCRATCH=true make <container>
```

### Rebuild a container
Если необходимо перестроить уже созданный контейнер, надо удалить файл `.state` в папке контейнера: `<container>/.state`.
В противном случае `make` не запустит пересборку при отсутствии изменений в зависимостях контейнера.

### Push a container
Сохранить контейнер <container> с тегом `latest` в __rbkmoney__ _docker hub_.

```
CONTAINER=<container> make push
```

