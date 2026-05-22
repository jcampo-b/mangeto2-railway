<?php

declare(strict_types=1);

namespace Braintly\Caas\Helper;

use Braintly\Caas\Model\Config\Source\ButtonPosition;
use Magento\Framework\App\Helper\AbstractHelper;
use Magento\Store\Model\ScopeInterface;

class Config extends AbstractHelper
{
    private const XML_PATH_ENABLED         = 'braintly_caas/general/enabled';
    private const XML_PATH_API_URL         = 'braintly_caas/general/api_url';
    private const XML_PATH_BUTTON_POSITION = 'braintly_caas/general/button_position';
    private const XML_PATH_CUSTOM_SELECTOR = 'braintly_caas/general/custom_selector';

    private const ALLOWED_POSITIONS = [
        ButtonPosition::BEFORE_ADDTOCART,
        ButtonPosition::AFTER_DESCRIPTION,
        ButtonPosition::AFTER_PRICE,
        ButtonPosition::AFTER_SKU,
    ];

    public function isEnabled(): bool
    {
        return $this->scopeConfig->isSetFlag(
            self::XML_PATH_ENABLED,
            ScopeInterface::SCOPE_STORE
        );
    }

    public function getApiUrl(): string
    {
        return rtrim(trim(
            (string) $this->scopeConfig->getValue(
                self::XML_PATH_API_URL,
                ScopeInterface::SCOPE_STORE
            )
        ), '/');
    }

    public function getButtonPosition(): string
    {
        $value = (string) $this->scopeConfig->getValue(
            self::XML_PATH_BUTTON_POSITION,
            ScopeInterface::SCOPE_STORE
        );

        return in_array($value, self::ALLOWED_POSITIONS, true)
            ? $value
            : ButtonPosition::BEFORE_ADDTOCART;
    }

    public function getCustomSelector(): string
    {
        return trim(
            (string) $this->scopeConfig->getValue(
                self::XML_PATH_CUSTOM_SELECTOR,
                ScopeInterface::SCOPE_STORE
            )
        );
    }

    public function hasCustomSelector(): bool
    {
        return $this->getCustomSelector() !== '';
    }
}
