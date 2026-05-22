<?php

namespace Braintly\Caas\Block\Product;

use Braintly\Caas\Helper\Config;
use Magento\Catalog\Model\Product;
use Magento\Customer\Model\Session as CustomerSession;
use Magento\Framework\Registry;
use Magento\Framework\View\Element\Template;
use Magento\Framework\View\Element\Template\Context;
use Magento\Store\Model\StoreManagerInterface;

class CaasWidget extends Template
{
    public function __construct(
        Context $context,
        private readonly Config $config,
        private readonly Registry $registry,
        private readonly StoreManagerInterface $storeManager,
        private readonly CustomerSession $customerSession,
        array $data = []
    ) {
        parent::__construct($context, $data);
    }

    public function isEnabled(): bool
    {
        return $this->config->isEnabled();
    }

    public function getApiUrl(): string
    {
        return $this->config->getApiUrl();
    }

    /**
     * Base URL de la tienda Magento — coincide con el external_id
     * registrado en CAAS al conectar via POST /magento/connect.
     */
    public function getStoreId(): string
    {
        return rtrim($this->storeManager->getStore()->getBaseUrl(), '/');
    }

    /**
     * Entity ID del producto actual — coincide con el external_id
     * sincronizado por MagentoService.
     */
    public function getProductId(): string
    {
        /** @var Product|null $product */
        $product = $this->registry->registry('current_product');
        return $product ? (string) $product->getId() : '';
    }

    /**
     * ID del cliente logueado, o null si es invitado.
     */
    public function getCustomerId(): ?string
    {
        $id = $this->customerSession->getCustomerId();
        return $id ? (string) $id : null;
    }
}
