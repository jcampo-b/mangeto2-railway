<?php

declare(strict_types=1);

namespace Braintly\Caas\Block\Product;

use Braintly\Caas\Helper\Config;
use Magento\Catalog\Model\Product;
use Magento\Framework\Registry;
use Magento\Framework\View\Element\Template;
use Magento\Framework\View\Element\Template\Context;

class ButtonContainer extends Template
{
    private const DEFAULT_CONTAINER_ID = 'caas-button-container';

    public function __construct(
        Context $context,
        private readonly Config $config,
        private readonly Registry $registry,
        array $data = []
    ) {
        parent::__construct($context, $data);
    }

    public function shouldRender(): bool
    {
        if (!$this->config->isEnabled()) {
            return false;
        }

        /** @var Product|null $product */
        $product = $this->registry->registry('current_product');
        if (!$product || !$product->getId()) {
            return false;
        }

        if ($this->config->hasCustomSelector()) {
            return false;
        }

        return $this->getPosition() === $this->config->getButtonPosition();
    }

    public function getContainerId(): string
    {
        return self::DEFAULT_CONTAINER_ID;
    }

    public function getPosition(): string
    {
        return (string) $this->getData('position');
    }
}
