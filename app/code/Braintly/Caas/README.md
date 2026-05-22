# Braintly CAAS — Magento 2 Module

Inyecta el widget "Encontrar mi talle" de CAAS (Clothing-as-a-Service) en páginas de producto de Magento 2.

---

# Requisitos

* Magento 2.4.x
* PHP >= 8.1
* CAAS API accesible desde la tienda vía HTTPS
* Acceso al repositorio privado de GitHub

---

# composer.json del módulo

```json
{
  "name": "braintly/module-caas",
  "description": "Magento 2 module that injects the Braintly CAAS Find My Size widget on product pages.",
  "type": "magento2-module",
  "license": "proprietary",
  "require": {
    "php": ">=8.1",
    "magento/framework": "^103.0",
    "magento/module-catalog": "^104.0",
    "magento/module-customer": "^103.0",
    "magento/module-store": "^101.0",
    "magento/module-config": "^101.0"
  },
  "autoload": {
    "files": [
      "registration.php"
    ],
    "psr-4": {
      "Braintly\\Caas\\": ""
    }
  }
}
```

---

# Instalación vía Composer (Repositorio Privado GitHub)

> Recomendado para ambientes productivos.

## Opción A — Acceso vía SSH (Recomendado)

### 1. Asegurar acceso SSH al repositorio privado

El servidor Magento debe tener una SSH key con acceso al repositorio:

```txt
git@github.com:Braintly/CAAS-Magento.git
```

Verificar acceso:

```bash
ssh -T git@github.com
```

---

### 2. Configurar el repositorio privado en Magento

Ejecutar desde la raíz del proyecto Magento:

```bash
composer config repositories.braintly-caas vcs git@github.com:Braintly/CAAS-Magento.git
```

---

### 3. Instalar el módulo

```bash
composer require braintly/module-caas:^1.0
```

---

### 4. Habilitar el módulo y correr setup

```bash
bin/magento module:enable Braintly_Caas
bin/magento setup:upgrade
bin/magento cache:flush
```

---

### 5. Configurar el módulo en Magento Admin

Ir a:

```txt
Stores > Configuration > Braintly > CAAS — Find My Size
```

Configurar:

* Enable Widget → Yes
* CAAS API URL → URL base de la API CAAS

Ejemplo:

```txt
https://caas-api-prod.example.com
```

---

### 6. Registrar la tienda Magento en CAAS

La tienda debe estar registrada vía:

```txt
POST /api/v1/magento/connect
```

Repositorio:

urlCAAS-API Repository[https://github.com/Braintly/CAAS-API](https://github.com/Braintly/CAAS-API)

---

# Opción B — HTTPS + GitHub Token

Usar esto si no hay acceso SSH disponible.

---

## 1. Configurar el repositorio

```bash
composer config repositories.braintly-caas vcs https://github.com/Braintly/CAAS-Magento.git
```

---

## 2. Configurar autenticación GitHub

Globalmente:

```bash
composer config --global github-oauth.github.com YOUR_GITHUB_TOKEN
```

O localmente en el proyecto Magento:

```bash
composer config github-oauth.github.com YOUR_GITHUB_TOKEN
```

> No commitear `auth.json`.

---

## 3. Instalar el módulo

```bash
composer require braintly/module-caas:^1.0
```

---

## 4. Habilitar el módulo

```bash
bin/magento module:enable Braintly_Caas
bin/magento setup:upgrade
bin/magento cache:flush
```

---

# Instalación vía ZIP

También es posible instalar el módulo manualmente vía ZIP, sin Composer.

> Recomendado únicamente para desarrollo, pruebas rápidas o clientes sin acceso Composer.

## 1. Descargar el ZIP del módulo

Descargar el ZIP del repositorio privado:

```txt
CAAS-Magento.zip
```

---

## 2. Extraer el módulo dentro de Magento

La estructura final debe quedar así:

```txt
app/code/Braintly/Caas/
```

Ejemplo:

```txt
app/code/Braintly/Caas/composer.json
app/code/Braintly/Caas/registration.php
app/code/Braintly/Caas/etc/module.xml
```

---

## 3. Habilitar el módulo

Desde la raíz de Magento:

```bash
bin/magento module:enable Braintly_Caas
bin/magento setup:upgrade
bin/magento cache:flush
```

---

## 4. Verificar instalación

Verificar que el módulo aparezca habilitado:

```bash
bin/magento module:status Braintly_Caas
```

---

## 5. Configurar el módulo

Ir a:

```txt
Stores > Configuration > Braintly > CAAS — Find My Size
```

Configurar:

* Enable Widget → Yes
* CAAS API URL → URL base de la API CAAS

---

# Instalación Manual para Desarrollo

## 1. Clonar el módulo dentro de Magento

```bash
git clone git@github.com:Braintly/CAAS-Magento.git app/code/Braintly/Caas
```

---

## 2. Habilitar y aplicar setup

```bash
bin/magento module:enable Braintly_Caas
bin/magento setup:upgrade
bin/magento cache:flush
```

---

## 3. Configurar el módulo

Ir a:

```txt
Stores > Configuration > Braintly > CAAS — Find My Size
```

Configurar:

* Enable Widget → Yes
* CAAS API URL → URL base de la API CAAS

---

# Cómo Funciona

El módulo inyecta antes del cierre del `<body>` en páginas de producto:

```html
<script>
  window.CAAS_CONFIG = {
    store_id: "<base-url-magento>",
    product_id: "<entity-id-producto>",
    customer_id: "<customer-id-o-null>"
  };
</script>
<script src="<CAAS-API-URL>/magento-measurements-script.js" defer></script>
```

El script remoto se encarga del resto:

* Render del botón
* Modal
* Integración con API
* Avatar
* Flujo de mediciones
* Persistencia

---

# Versionado

Composer utiliza Git tags para resolver versiones.

## Publicar una nueva versión

```bash
git tag 1.0.0
git push origin 1.0.0
```

---

## Publicar un patch

```bash
git tag 1.0.1
git push origin 1.0.1
```

---

## Actualizar el módulo en Magento

```bash
composer update braintly/module-caas
bin/magento setup:upgrade
bin/magento cache:flush
```

---

# Desarrollo Local

Para desarrollo local se recomienda:

urlmarkshust/docker-magento[https://github.com/markshust/docker-magento](https://github.com/markshust/docker-magento)

Clonar o bind-mountear el módulo en:

```txt
src/app/code/Braintly/Caas/
```

Y luego habilitarlo:

```bash
bin/magento module:enable Braintly_Caas
bin/magento setup:upgrade
bin/magento cache:flush
```

---

# Estructura Esperada del Módulo

```txt
Braintly/Caas/
├── composer.json
├── registration.php
├── etc/
│   └── module.xml
├── Block/
├── Controller/
├── Helper/
├── Model/
├── Plugin/
├── Observer/
├── view/
└── ...
```

---

# module.xml

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Module/etc/module.xsd">
    <module name="Braintly_Caas" setup_version="1.0.0"/>
</config>
```

---

# registration.php

```php
<?php

use Magento\Framework\Component\ComponentRegistrar;

ComponentRegistrar::register(
    ComponentRegistrar::MODULE,
    'Braintly_Caas',
    __DIR__
);
```
