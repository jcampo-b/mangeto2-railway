<?php

namespace Braintly\Caas\Helper;

use Magento\Framework\App\Helper\AbstractHelper;
use Magento\Store\Model\ScopeInterface;

class Config extends AbstractHelper
{
    private const XML_PATH_ENABLED = 'braintly_caas/general/enabled';
    private const XML_PATH_API_URL = 'braintly_caas/general/api_url';

    public function isEnabled(): bool
    {
        return $this->scopeConfig->isSetFlag(
            self::XML_PATH_ENABLED,
            ScopeInterface::SCOPE_STORE
        );
    }

    public function getApiUrl(): string
    {
        return rtrim(
            (string) $this->scopeConfig->getValue(
                self::XML_PATH_API_URL,
                ScopeInterface::SCOPE_STORE
            ),
            '/'
        );
    }
}
