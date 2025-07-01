# Himalaya Scripts

This directory contains helper scripts for the Himalaya email plugin.

## refresh-gmail-oauth2

The standard OAuth refresh script for Gmail accounts. This script refreshes tokens for the main Gmail account using the `gmail-smtp-oauth2-*` token naming pattern.

Usage: refresh-gmail-oauth2

## refresh-himalaya-oauth2

Wrapper script that refreshes OAuth tokens for any Himalaya account, including IMAP accounts.

The standard refresh-gmail-oauth2 script only works for gmail-smtp tokens. This wrapper handles any account including gmail-imap.

Usage: refresh-himalaya-oauth2 [account-name]

Examples:
- `refresh-himalaya-oauth2` - Refreshes main gmail account
- `refresh-himalaya-oauth2 gmail-imap` - Refreshes gmail-imap account
