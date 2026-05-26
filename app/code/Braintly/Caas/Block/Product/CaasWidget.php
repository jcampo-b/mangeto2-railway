<?php

declare(strict_types=1);

namespace Braintly\Caas\Block\Product;

use Braintly\Caas\Helper\Config;
use Magento\Catalog\Model\Product;
use Magento\Framework\Registry;
use Magento\Framework\UrlInterface;
use Magento\Framework\View\Element\Template;
use Magento\Framework\View\Element\Template\Context;
use Magento\Store\Model\StoreManagerInterface;

class CaasWidget extends Template
{
    private const DEFAULT_CONTAINER_ID = 'caas-button-container';

    public function __construct(
        Context $context,
        private readonly Config $config,
        private readonly Registry $registry,
        private readonly StoreManagerInterface $storeManager,
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

    public function getStoreId(): string
    {
        return $this->normalizeStoreUrl(
            (string) $this->storeManager->getStore()->getBaseUrl(UrlInterface::URL_TYPE_WEB)
        );
    }

    public function getProductId(): string
    {
        /** @var Product|null $product */
        $product = $this->registry->registry('current_product');

        return $product ? (string) $product->getId() : '';
    }

    public function getContainerId(): ?string
    {
        if ($this->config->hasCustomSelector()) {
            return null;
        }

        return self::DEFAULT_CONTAINER_ID;
    }

    public function getTargetSelector(): ?string
    {
        if (!$this->config->hasCustomSelector()) {
            return null;
        }

        return $this->config->getCustomSelector();
    }

    private function normalizeStoreUrl(string $url): string
    {
        $url = trim($url);

        if ($url === '') {
            return '';
        }

        $url = preg_replace('#/index\.php/?$#', '', $url);

        return rtrim((string) $url, '/');
    }
}